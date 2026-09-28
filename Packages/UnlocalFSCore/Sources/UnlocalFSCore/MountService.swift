import Foundation

public struct MountStatus: Equatable, Sendable {
    public var isMounted = false
    public var isRunning = false
    public var pendingUploads = 0
    public var failedUploads = 0
    public var bytesCached: Int64 = 0
    public init() {}

    public var isActive: Bool { isMounted || isRunning }
    public var hasUnfinishedUploads: Bool { pendingUploads > 0 || failedUploads > 0 }
}

public actor MountService {
    private let executable: URL
    private let helperDirectory: URL
    private let paths: AppPaths
    private var processes: [UUID: Process] = [:]
    private var starting: Set<UUID> = []

    public init(executable: URL, helperDirectory: URL, paths: AppPaths) {
        self.executable = executable
        self.helperDirectory = helperDirectory
        self.paths = paths
    }

    public func test(_ connection: Connection, credentials: Credentials) async throws {
        try AppError.throwing(connection.validate() + credentials.validate())
        do {
            _ = try await Command.run(executable, [
                "lsf", remote(connection), "--max-depth", "1", "--dirs-only",
                "--config", "/dev/null", "--retries", "1", "--low-level-retries", "1",
                "--contimeout", "5s", "--timeout", "10s"
            ], environment: environment(connection, credentials: credentials), timeout: .seconds(20))
        } catch {
            throw redacted(error, credentials: credentials)
        }
    }

    public func mount(_ connection: Connection, credentials: Credentials) async throws {
        guard !starting.contains(connection.id) else { throw AppError("This drive is already connecting.") }
        starting.insert(connection.id)
        defer { starting.remove(connection.id) }
        guard try await !status(connection).isActive else { throw AppError("This drive is already running. Disconnect it first.") }
        try await test(connection, credentials: credentials)
        try paths.prepare()
        let mount = paths.mount(connection)
        try FileManager.default.createDirectory(at: mount, withIntermediateDirectories: true)
        guard try FileManager.default.contentsOfDirectory(atPath: mount.path).isEmpty else {
            throw AppError("The mount folder contains files. Move them before connecting: \(mount.path)")
        }
        let socket = paths.socket(connection)
        if FileManager.default.fileExists(atPath: socket.path) { try FileManager.default.removeItem(at: socket) }
        let logURL = paths.log(connection)
        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil, attributes: [.posixPermissions: 0o600])
        }
        let log = try FileHandle(forWritingTo: logURL)
        try log.seekToEnd()
        defer { try? log.close() }
        let process = Process()
        process.executableURL = executable
        var arguments = [
            "nfsmount", remote(connection), mount.path,
            "--config", "/dev/null", "--vfs-cache-mode", "full",
            "--cache-dir", paths.cache(connection).path,
            "--vfs-cache-max-size", "\(connection.cacheLimit)B",
            "--vfs-cache-min-free-space", connection.minimumFreeSpace > 0 ? "\(connection.minimumFreeSpace)B" : "off",
            "--s3-directory-markers", "--rc", "--rc-no-auth",
            "--rc-addr", "unix://\(socket.path)", "--log-level", "INFO"
        ]
        if connection.readOnly { arguments.append("--read-only") }
        process.arguments = arguments
        process.environment = environment(connection, credentials: credentials)
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = log
        process.standardError = log
        try process.run()
        processes[connection.id] = process
        for _ in 0..<60 {
            if isMounted(mount) { return }
            guard process.isRunning else {
                processes[connection.id] = nil
                throw AppError("The drive could not mount. Open its log for details.")
            }
            try await Task.sleep(for: .milliseconds(250))
        }
        process.terminate()
        processes[connection.id] = nil
        throw AppError("The drive took too long to mount. Open its log for details.")
    }

    public func status(_ connection: Connection) async throws -> MountStatus {
        var status = MountStatus()
        status.isMounted = isMounted(paths.mount(connection))
        guard FileManager.default.fileExists(atPath: paths.socket(connection).path) else {
            if status.isMounted { throw AppError("The drive is mounted, but its control service is unavailable. Do not delete its cache.") }
            status.isRunning = isRunning(connection)
            return status
        }
        let data: Data
        do {
            data = try await control(connection, "vfs/stats")
        } catch {
            if status.isMounted || isRunning(connection) { throw error }
            return status
        }
        let cache = try JSONDecoder().decode(VFSStats.self, from: data).diskCache
        status.isRunning = true
        status.pendingUploads = cache.uploadsQueued + cache.uploadsInProgress
        status.failedUploads = cache.erroredFiles
        status.bytesCached = cache.bytesUsed
        return status
    }

    public func activity(_ connection: Connection) async throws -> [FileActivity] {
        async let queueData = control(connection, "vfs/queue")
        async let statsData = control(connection, "core/stats")
        let queue = try await JSONDecoder().decode(UploadQueue.self, from: queueData).queue
        let transfers = try await JSONDecoder().decode(TransferStats.self, from: statsData).transferring ?? []
        let queuedPaths = Set(queue.map(\.name))
        let queued = queue.map { item in
            let state: FileActivity.State = item.uploading ? .uploading : item.tries > 0 ? .retrying : .queued
            let transfer = item.uploading ? transfers.first { $0.isUpload && $0.name == item.name } : nil
            return FileActivity(path: item.name, size: item.size, state: state, bytesTransferred: transfer?.bytes)
        }
        let transferring = transfers.filter { !$0.isUpload || !queuedPaths.contains($0.name) }.map {
            FileActivity(path: $0.name, size: $0.size, state: $0.isUpload ? .uploading : .downloading, bytesTransferred: $0.bytes)
        }
        return (queued + transferring).sorted(using: KeyPathComparator(\.path, comparator: .localizedStandard))
    }

    public func unmount(_ connection: Connection) async throws {
        let current = try await status(connection)
        guard !current.hasUnfinishedUploads else {
            throw AppError("Files are still uploading or need a retry. Keep this drive connected until uploads finish.")
        }
        if current.isMounted {
            do {
                _ = try await Command.run(URL(filePath: "/sbin/umount"), [paths.mount(connection).path], timeout: .seconds(10))
            } catch {
                throw AppError("Could not eject the drive. Close files using it and try again.\n\n\(error.localizedDescription)")
            }
            for _ in 0..<20 {
                if !isMounted(paths.mount(connection)) { break }
                try await Task.sleep(for: .milliseconds(100))
            }
        }
        if current.isRunning {
            let remaining = try await status(connection)
            guard !remaining.hasUnfinishedUploads else {
                throw AppError("The drive was ejected, but uploads are still finishing. Disconnect again after they complete.")
            }
            if remaining.isRunning { try await stop(connection) }
        }
        processes[connection.id] = nil
    }

    private func stop(_ connection: Connection) async throws {
        var quitError: (any Error)?
        do {
            _ = try await control(connection, "core/quit")
        } catch {
            quitError = error
        }
        for _ in 0..<20 {
            if !isRunning(connection),
               !FileManager.default.fileExists(atPath: paths.socket(connection).path),
               !isMounted(paths.mount(connection)) {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        guard try await !status(connection).isActive else {
            throw quitError ?? AppError("The drive is still stopping. Wait a moment and try disconnecting again.")
        }
    }

    private func control(_ connection: Connection, _ method: String) async throws -> Data {
        try await Command.run(executable, [
            "rc", "--unix-socket", paths.socket(connection).path, method, "--config", "/dev/null"
        ], environment: baseEnvironment, timeout: .seconds(4))
    }

    private func remote(_ connection: Connection) -> String {
        connection.folder.isEmpty ? ":s3:\(connection.bucket)" : ":s3:\(connection.bucket)/\(connection.folder)"
    }

    private func isRunning(_ connection: Connection) -> Bool {
        processes[connection.id]?.isRunning == true
    }

    private var baseEnvironment: [String: String] {
        ["HOME": URL.homeDirectory.path,
         "PATH": "\(helperDirectory.path):/usr/bin:/bin:/usr/sbin:/sbin",
         "TMPDIR": URL.temporaryDirectory.path,
         "LANG": "en_US.UTF-8"]
    }

    private func environment(_ connection: Connection, credentials: Credentials) -> [String: String] {
        baseEnvironment.merging([
            "RCLONE_S3_PROVIDER": connection.provider.rawValue,
            "RCLONE_S3_ENDPOINT": connection.endpoint,
            "RCLONE_S3_REGION": connection.region,
            "RCLONE_S3_ACCESS_KEY_ID": credentials.accessKey,
            "RCLONE_S3_SECRET_ACCESS_KEY": credentials.secretKey,
            "RCLONE_S3_SESSION_TOKEN": credentials.sessionToken,
            "RCLONE_S3_ENV_AUTH": "false",
            "UNLOCALFS_VOLUME_NAME": connection.name
        ]) { _, new in new }
    }

    private func redacted(_ error: any Error, credentials: Credentials) -> AppError {
        var message = error.localizedDescription
        for secret in [credentials.accessKey, credentials.secretKey, credentials.sessionToken] where !secret.isEmpty {
            message = message.replacingOccurrences(of: secret, with: "[redacted]")
        }
        return AppError(message)
    }

    private func isMounted(_ url: URL) -> Bool {
        let path = url.resolvingSymlinksInPath().path
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [], options: []) ?? []
        return volumes.contains { $0.resolvingSymlinksInPath().path == path }
    }
}

private struct VFSStats: Decodable {
    let diskCache: DiskCache

    struct DiskCache: Decodable {
        let uploadsQueued: Int
        let uploadsInProgress: Int
        let erroredFiles: Int
        let bytesUsed: Int64
    }
}

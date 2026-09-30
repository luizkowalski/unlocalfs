import Darwin
import Foundation

public struct UploadsPendingError: LocalizedError, Sendable {
    public init() {}

    public var errorDescription: String? {
        "Uploads are still in progress. Wait for them to finish before disconnecting."
    }
}

public struct MountStatus: Equatable, Sendable {
    public var isMounted = false
    public var isRunning = false
    public var pendingUploads = 0
    public var failedUploads = 0
    public var bytesCached: Int64 = 0
    public var controlError: String?
    public init() {}

    public var isActive: Bool { isMounted || isRunning || needsReconnect }
    public var needsReconnect: Bool { controlError != nil }
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
        try AppError.throwing(connection.validate() + credentials.validate(for: connection))
        let credentials = try await prepareCredentials(credentials)
        do {
            _ = try await Command.run(executable, [
                "lsf", connection.encrypted ? ":crypt:" : remote(connection), "--max-depth", "1", "--dirs-only", "--crypt-strict-names",
                "--config", "/dev/null", "--retries", "1", "--low-level-retries", "1",
                "--contimeout", "5s", "--timeout", "10s"
            ], environment: environment(connection, credentials: credentials), timeout: .seconds(20))
        } catch {
            throw redacted(error, credentials: credentials)
        }
    }

    public func prepareCredentials(_ credentials: Credentials) async throws -> Credentials {
        var credentials = credentials
        if !credentials.encryptionPassword.isEmpty, credentials.obscuredEncryptionPassword.isEmpty {
            let output = try await Command.run(executable, ["obscure", "-", "--config", "/dev/null"], input: credentials.encryptionPassword, environment: baseEnvironment)
            credentials.obscuredEncryptionPassword = String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return credentials
    }

    public func mount(_ connection: Connection, credentials: Credentials) async throws {
        guard !starting.contains(connection.id) else { throw AppError("This drive is already connecting.") }
        starting.insert(connection.id)
        defer { starting.remove(connection.id) }
        guard await !status(connection).isActive else { throw AppError("This drive is already running. Disconnect it first.") }
        let credentials = try await prepareCredentials(credentials)
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
        process.arguments = mountArguments(for: connection, mount: mount, socket: socket)
        process.environment = environment(connection, credentials: credentials)
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = log
        process.standardError = log
        try process.run()
        processes[connection.id] = process
        do {
            try String(process.processIdentifier).write(to: paths.pidFile(connection), atomically: true, encoding: .utf8)
        } catch {
            process.terminate()
            throw error
        }
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

    public func status(_ connection: Connection) async -> MountStatus {
        var status = MountStatus()
        status.isMounted = isMounted(paths.mount(connection))
        let running = isRunning(connection)
        status.isRunning = running == true
        guard FileManager.default.fileExists(atPath: paths.socket(connection).path) else {
            if status.isActive {
                status.controlError = "The drive's control service is unavailable. Reconnect to restore the drive. Its cache will be kept."
            }
            return status
        }
        do {
            let data = try await control(connection, "vfs/stats")
            let cache = try JSONDecoder().decode(VFSStats.self, from: data).diskCache
            status.isRunning = true
            status.pendingUploads = cache.uploadsQueued + cache.uploadsInProgress
            status.failedUploads = cache.erroredFiles
            if status.pendingUploads > 0 {
                let queue = try await JSONDecoder().decode(UploadQueue.self, from: control(connection, "vfs/queue")).queue
                status.failedUploads += queue.count { $0.tries > 0 }
            }
            status.bytesCached = cache.bytesUsed
        } catch {
            if status.isMounted || running != false {
                status.controlError = "The drive's control service is unavailable. Its cache will be kept.\n\n\(error.localizedDescription)"
            }
        }
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

    public func refresh(_ connection: Connection) async throws {
        _ = try await control(connection, "vfs/forget")
    }

    public func unmount(_ connection: Connection) async throws {
        try await disconnect(connection, recovering: false)
    }

    public func reconnect(_ connection: Connection, credentials: Credentials) async throws {
        try await disconnect(connection, recovering: true)
        try await mount(connection, credentials: credentials)
    }

    private func disconnect(_ connection: Connection, recovering: Bool) async throws {
        let current = await status(connection)
        if let error = current.controlError, !recovering { throw AppError(error) }
        if current.needsReconnect, isRunning(connection) == nil {
            throw AppError("Could not stop the old drive service because its process could not be identified. The cache was kept.")
        }
        try checkUploads(current)
        if current.isMounted { try await eject(connection, force: !current.isRunning) }
        if current.needsReconnect {
            try await stop(connection)
        } else if current.isRunning {
            let remaining = await status(connection)
            try checkUploads(remaining)
            if let error = remaining.controlError {
                try await waitForStop(connection, error: AppError(error))
            } else if remaining.isRunning {
                try await stop(connection)
            }
        }
        processes[connection.id] = nil
        let pidFile = paths.pidFile(connection)
        if FileManager.default.fileExists(atPath: pidFile.path) { try FileManager.default.removeItem(at: pidFile) }
    }

    private func checkUploads(_ status: MountStatus) throws {
        guard status.failedUploads == 0 else {
            throw AppError("Some files could not upload and need a retry. Keep UnlocalFS running until uploads finish.")
        }
        guard status.pendingUploads == 0 else { throw UploadsPendingError() }
    }

    private func control(_ connection: Connection, _ method: String) async throws -> Data {
        try await Command.run(executable, [
            "rc", "--unix-socket", paths.socket(connection).path, method, "--config", "/dev/null"
        ], environment: baseEnvironment, timeout: .seconds(4))
    }

    private func remote(_ connection: Connection) -> String {
        connection.folder.isEmpty ? ":s3:\(connection.bucket)" : ":s3:\(connection.bucket)/\(connection.folder)"
    }

    private func mountArguments(for connection: Connection, mount: URL, socket: URL) -> [String] {
        var arguments = [
            "nfsmount", connection.encrypted ? ":crypt:" : remote(connection), mount.path,
            "--config", "/dev/null", "--vfs-cache-mode", "full",
            "--cache-dir", paths.cache(connection).path, "--vfs-cache-max-size", "\(connection.cacheLimit)B",
            "--vfs-cache-min-free-space", connection.minimumFreeSpace > 0 ? "\(connection.minimumFreeSpace)B" : "off",
            "--transfers", "\(connection.transfers)", "--default-time", Date.now.ISO8601Format(),
            "--s3-directory-markers", "--rc", "--rc-no-auth",
            "--rc-addr", "unix://\(socket.path)", "--log-level", "INFO"
        ]
        if connection.bandwidthLimit > 0 { arguments += ["--bwlimit", "\(connection.bandwidthLimit)B"] }
        if connection.readOnly { arguments.append("--read-only") }
        return arguments
    }

    private func isRunning(_ connection: Connection) -> Bool? {
        guard let saved = try? String(contentsOf: paths.pidFile(connection), encoding: .utf8),
              let pid = pid_t(saved), pid > 0 else {
            return processes[connection.id]?.isRunning
        }
        if let process = processes[connection.id], process.processIdentifier == pid { return process.isRunning }
        return kill(pid, 0) == 0 || errno != ESRCH
    }

    private var baseEnvironment: [String: String] {
        ["HOME": URL.homeDirectory.path,
         "PATH": "\(helperDirectory.path):/usr/bin:/bin:/usr/sbin:/sbin",
         "TMPDIR": URL.temporaryDirectory.path,
         "LANG": "en_US.UTF-8"]
    }

    private func environment(_ connection: Connection, credentials: Credentials) -> [String: String] {
        var environment = baseEnvironment.merging([
            "RCLONE_S3_PROVIDER": connection.provider.rawValue,
            "RCLONE_S3_ENDPOINT": connection.endpoint,
            "RCLONE_S3_REGION": connection.region,
            "RCLONE_S3_ACCESS_KEY_ID": credentials.accessKey,
            "RCLONE_S3_SECRET_ACCESS_KEY": credentials.secretKey,
            "RCLONE_S3_SESSION_TOKEN": credentials.sessionToken,
            "RCLONE_S3_ENV_AUTH": "false",
            "UNLOCALFS_VOLUME_NAME": connection.name
        ]) { _, new in new }
        if connection.encrypted {
            environment["RCLONE_CRYPT_REMOTE"] = remote(connection)
            environment["RCLONE_CRYPT_PASSWORD"] = credentials.obscuredEncryptionPassword
        }
        return environment
    }

    private func redacted(_ error: any Error, credentials: Credentials) -> AppError {
        var message = error.localizedDescription
        let secrets = [
            credentials.accessKey, credentials.secretKey, credentials.sessionToken,
            credentials.encryptionPassword, credentials.obscuredEncryptionPassword
        ]
        for secret in secrets where !secret.isEmpty {
            message = message.replacingOccurrences(of: secret, with: "[redacted]")
        }
        return AppError(message)
    }

    private func isMounted(_ url: URL) -> Bool {
        guard let parent = realpath(url.deletingLastPathComponent().path, nil) else { return false }
        defer { free(parent) }
        let path = URL(filePath: String(cString: parent)).appending(path: url.lastPathComponent).path
        var mounts: UnsafeMutablePointer<statfs>?
        let count = getmntinfo_r_np(&mounts, MNT_NOWAIT)
        guard let mounts else { return false }
        defer { free(mounts) }
        return (0..<Int(count)).contains { index in
            withUnsafePointer(to: mounts[index].f_mntonname) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { String(cString: $0) == path }
            }
        }
    }
}

extension MountService {
    public func shareLink(for connection: Connection, path: String, expiry: ShareLinkExpiry, credentials: Credentials) async throws -> URL {
        guard !connection.encrypted else {
            throw AppError("Links aren't available for encrypted drives because they would point to encrypted data.")
        }
        try AppError.throwing(connection.validate() + credentials.validate(for: connection))
        if FileManager.default.fileExists(atPath: paths.socket(connection).path) {
            let pending: [FileActivity]
            do {
                pending = try await activity(connection)
            } catch {
                throw AppError("Reconnect the drive to create links. UnlocalFS could not check whether the file is still uploading.\n\n\(error.localizedDescription)")
            }
            if pending.contains(where: { $0.path == path && $0.state != .downloading }) {
                throw AppError("This file is still uploading. Wait for it to finish, then copy the link again.")
            }
        }
        let output: Data
        do {
            output = try await Command.run(executable, [
                "link", "\(remote(connection))/\(path)", "--expire", expiry.rawValue, "--quiet",
                "--config", "/dev/null", "--retries", "1", "--low-level-retries", "1",
                "--contimeout", "5s", "--timeout", "10s"
            ], environment: environment(connection, credentials: credentials), timeout: .seconds(20))
        } catch {
            throw AppError("""
            Could not create a link. If the file is still uploading, wait for it to finish.

            \(redacted(error, credentials: credentials).localizedDescription)
            """)
        }
        guard let link = URL(string: String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)),
              ["http", "https"].contains(link.scheme) else {
            throw AppError("Could not create a link. Try again.")
        }
        return link
    }
}

private extension MountService {
    func eject(_ connection: Connection, force: Bool) async throws {
        do {
            _ = try await Command.run(URL(filePath: "/sbin/umount"), (force ? ["-f"] : []) + [paths.mount(connection).path], timeout: .seconds(60))
        } catch {
            throw AppError("Could not eject the drive. Close files using it and try again.\n\n\(error.localizedDescription)")
        }
        for _ in 0..<20 {
            if !isMounted(paths.mount(connection)) { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw AppError("The drive is still mounted. Close files using it and try again.")
    }

    func stop(_ connection: Connection) async throws {
        var quitError: any Error = AppError("The drive is still stopping. Wait a moment and try disconnecting again.")
        do {
            _ = try await control(connection, "core/quit")
        } catch {
            quitError = error
        }
        try await waitForStop(connection, error: quitError)
    }

    func waitForStop(_ connection: Connection, error: any Error) async throws {
        for _ in 0..<20 {
            let running = isRunning(connection)
            let socket = paths.socket(connection)
            if running != true, !isMounted(paths.mount(connection)) {
                if !FileManager.default.fileExists(atPath: socket.path) { return }
                if running == false {
                    try FileManager.default.removeItem(at: socket)
                    return
                }
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw error
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

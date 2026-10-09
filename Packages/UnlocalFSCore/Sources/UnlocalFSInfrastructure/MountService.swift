import Darwin
import Foundation
import UnlocalFSDomain

public actor MountService: DriveGateway {
    private static let timeout = "5s"
    private static let lowLevelTimeout = "10s"
    private static let ejectRetryTime: Duration = .seconds(10)

    let executable: URL
    private let helperDirectory: URL
    let paths: AppPaths
    private let serverTrust: SFTPTrustStore
    private let hostEnvironment: [String: String]
    private var processes: [UUID: Process] = [:]
    private var starting: Set<UUID> = []

    public init(
        executable: URL, helperDirectory: URL, paths: AppPaths,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.executable = executable
        self.helperDirectory = helperDirectory
        self.paths = paths
        serverTrust = SFTPTrustStore(paths: paths)
        hostEnvironment = environment
    }

    public nonisolated func remoteFile(_ file: URL, among connections: [Connection]) -> (connection: Connection, path: String)? {
        paths.drive(containing: file, among: connections)
    }

    public nonisolated func removeCache(_ connection: Connection) { paths.removeCache(connection) }

    public func test(_ connection: Connection, credentials: Credentials) async throws {
        let credentials = try await prepareCredentials(credentials)
        let remote = try await remote(for: connection, credentials: credentials)
        do {
            _ = try await Command.run(executable, [
                "lsf", remote.target, "--max-depth", "1", "--dirs-only", "--crypt-strict-names",
                "--config", "/dev/null", "--retries", "1", "--low-level-retries", "1",
                "--contimeout", Self.timeout, "--timeout", Self.lowLevelTimeout
            ], environment: environment(remote.environment), timeout: .seconds(20))
        } catch {
            let failure = redacted(error, credentials: credentials)
            let unknownKey = failure.localizedDescription.contains("knownhosts: key is unknown")
            let changedKey = failure.localizedDescription.contains("knownhosts: key mismatch")
            if connection.backend == .sftp, unknownKey || changedKey {
                throw try await serverTrust.challenge(connection.sftp, keyChanged: changedKey)
            }
            throw failure
        }
    }

    public func trustServer(_ challenge: ServerTrustChallenge) async throws { try await serverTrust.accept(challenge) }
    public func cancelServerTrust(_ challenge: ServerTrustChallenge) async { await serverTrust.cancel(challenge) }
    public func forgetServer(_ connection: Connection) async throws { try await serverTrust.forget(connection.sftp) }

    public func prepareCredentials(_ credentials: Credentials) async throws -> Credentials {
        var credentials = credentials
        if credentials.obscuredEncryptionPassword.isEmpty { credentials.obscuredEncryptionPassword = try await obscure(credentials.encryptionPassword) }
        if credentials.obscuredPassword.isEmpty { credentials.obscuredPassword = try await obscure(credentials.password) }
        if credentials.obscuredKeyPassphrase.isEmpty { credentials.obscuredKeyPassphrase = try await obscure(credentials.keyPassphrase) }
        return credentials
    }

    private func obscure(_ secret: String) async throws -> String {
        guard !secret.isEmpty else { return "" }
        let output = try await Command.run(executable, ["obscure", "-", "--config", "/dev/null"], input: secret, environment: baseEnvironment)
        return String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func mount(_ connection: Connection, credentials: Credentials) async throws {
        guard !starting.contains(connection.id) else { throw AppError(String(localized: .alreadyConnecting)) }
        starting.insert(connection.id)
        defer { starting.remove(connection.id) }
        guard await !status(connection).isActive else { throw AppError(String(localized: .alreadyRunning)) }
        let credentials = try await prepareCredentials(credentials)
        try await test(connection, credentials: credentials)
        try paths.prepare()
        let mount = paths.mount(connection)
        try FileManager.default.createDirectory(at: mount, withIntermediateDirectories: true)
        if let name = try mount.resourceValues(forKeys: [.nameKey]).name, name != mount.lastPathComponent {
            try FileManager.default.moveItem(at: mount.deletingLastPathComponent().appending(path: name), to: mount)
        }
        guard try FileManager.default.contentsOfDirectory(atPath: mount.path).isEmpty else {
            throw AppError(String(localized: .mountFolderContainsFiles(mount.path)))
        }
        let socket = paths.socket(connection)
        if FileManager.default.fileExists(atPath: socket.path) { try FileManager.default.removeItem(at: socket) }
        let logURL = paths.log(connection)
        let command = MountCommand(remote: try await remote(for: connection, credentials: credentials), paths: paths)
        let descriptor = open(logURL.path, O_WRONLY | O_APPEND | O_CREAT, 0o600)
        guard descriptor >= 0 else { throw AppError(String(localized: .couldNotOpenLog(String(cString: strerror(errno))))) }
        let log = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? log.close() }
        let process = Process()
        process.executableURL = executable
        process.arguments = command.arguments
        process.environment = environment(command.environment)
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
                throw AppError(String(localized: .couldNotMount))
            }
            try await Task.sleep(for: .milliseconds(250))
        }
        process.terminate()
        processes[connection.id] = nil
        throw AppError(String(localized: .mountTimedOut))
    }

    public func status(_ connection: Connection) async -> MountStatus {
        var status = MountStatus()
        status.isMounted = isMounted(paths.mount(connection))
        let running = isRunning(connection)
        status.isRunning = running == true
        guard FileManager.default.fileExists(atPath: paths.socket(connection).path) else {
            if status.isActive {
                status.controlError = String(localized: .controlServiceUnavailableReconnect)
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
                status.failedUploads += queue.count { !$0.uploading && $0.tries > 0 }
            }
            status.bytesCached = cache.bytesUsed
        } catch {
            if status.isMounted || running != false {
                status.controlError = String(localized: .controlServiceUnavailable(error.localizedDescription))
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
            return FileActivity(path: item.name, size: item.size, state: state, bytesTransferred: transfer?.bytes, bytesPerSecond: transfer?.speedAvg)
        }
        let transferring = transfers.filter { !$0.isUpload || !queuedPaths.contains($0.name) }.map {
            FileActivity(path: $0.name, size: $0.size, state: $0.isUpload ? .uploading : .downloading, bytesTransferred: $0.bytes, bytesPerSecond: $0.speedAvg)
        }
        return queued + transferring
    }

    public func refresh(_ connection: Connection) async throws { _ = try await control(connection, "vfs/forget") }

    public func unmount(_ connection: Connection) async throws { try await disconnect(connection, recovering: false) }

    public func reconnect(_ connection: Connection, credentials: Credentials) async throws {
        try await disconnect(connection, recovering: true)
        try await mount(connection, credentials: credentials)
    }

    private func disconnect(_ connection: Connection, recovering: Bool) async throws {
        let current = await status(connection)
        if let error = current.controlError, !recovering { throw AppError(error) }
        if current.needsReconnect, isRunning(connection) == nil {
            throw AppError(String(localized: .couldNotStopOldService))
        }
        try current.requireSafeDisconnect()
        if current.isMounted { try await eject(connection, force: !current.isRunning) }
        if current.needsReconnect {
            try await stop(connection)
        } else if current.isRunning {
            let remaining = await status(connection)
            try remaining.requireSafeDisconnect()
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

    private func control(_ connection: Connection, _ method: String) async throws -> Data {
        try await Command.run(executable, [
            "rc", "--unix-socket", paths.socket(connection).path, method, "--config", "/dev/null"
        ], environment: baseEnvironment, timeout: .seconds(4))
    }

    private func isRunning(_ connection: Connection) -> Bool? {
        guard let saved = try? String(contentsOf: paths.pidFile(connection), encoding: .utf8),
              let pid = pid_t(saved), pid > 0 else {
            return processes[connection.id]?.isRunning
        }
        if let process = processes[connection.id], process.processIdentifier == pid { return process.isRunning }
        return kill(pid, 0) == 0 || errno != ESRCH
    }

    var baseEnvironment: [String: String] {
        ["HOME": URL.homeDirectory.path,
         "PATH": "\(helperDirectory.path):/usr/bin:/bin:/usr/sbin:/sbin",
         "TMPDIR": URL.temporaryDirectory.path,
         "LANG": "en_US.UTF-8"]
    }

    private func environment(_ variables: [String: String]) -> [String: String] {
        baseEnvironment.merging(variables) { _, new in new }
    }

    private func remote(for connection: Connection, credentials: Credentials?) async throws -> RcloneRemote {
        switch connection.backend {
        case .s3Compatible, .gcs:
            return RcloneRemote(connection: connection, credentials: credentials, knownHosts: paths.knownHosts)
        case .sftp:
            let sftp = connection.sftp
            let knownHosts = try await serverTrust.file()
            if sftp.authentication == .privateKey { try requireReadableFile(sftp.keyPath, failure: { .cannotReadPrivateKeyFile($0) }) }
            let socket = sftp.authentication == .agent ? try agentSocket(sftp) : nil
            return RcloneRemote(connection: connection, credentials: credentials, knownHosts: knownHosts, agentSocket: socket)
        }
    }

    private func requireReadableFile(_ path: String, failure: (String) -> LocalizedStringResource) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue,
              FileManager.default.isReadableFile(atPath: path) else {
            throw AppError(String(localized: failure(path)))
        }
    }

    private func agentSocket(_ sftp: SFTPSettings) throws -> String {
        let path = sftp.agentSocket.isEmpty ? hostEnvironment["SSH_AUTH_SOCK"] : sftp.agentSocketPath
        let type = path.flatMap { try? FileManager.default.attributesOfItem(atPath: $0)[.type] as? FileAttributeType }
        guard let path, type == .typeSocket else {
            throw AppError(String(localized: .agentUnavailable))
        }
        return path
    }

    func redacted(_ error: any Error, credentials: Credentials) -> AppError {
        var message = error.localizedDescription
        let secrets = [
            credentials.accessKey, credentials.secretKey, credentials.sessionToken,
            credentials.encryptionPassword, credentials.obscuredEncryptionPassword,
            credentials.password, credentials.obscuredPassword, credentials.keyPassphrase, credentials.obscuredKeyPassphrase,
            credentials.serviceAccountKey
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
        guard isMounted(paths.mount(connection)), FileManager.default.fileExists(atPath: paths.socket(connection).path) else {
            throw AppError(String(localized: .reconnectForLinks))
        }
        let pending: [FileActivity]
        do {
            pending = try await activity(connection)
        } catch {
            throw AppError(String(localized: .reconnectToCheckUploads(error.localizedDescription)))
        }
        if pending.contains(where: { $0.path == path && $0.state != .downloading }) {
            throw AppError(String(localized: .fileStillUploading))
        }
        let remote = RcloneRemote(connection: connection, credentials: credentials, knownHosts: paths.knownHosts)
        let output: Data
        do {
            output = try await Command.run(executable, [
                "link", "\(remote.storage)/\(path)", "--expire", expiry.rawValue, "--quiet",
                "--config", "/dev/null", "--retries", "1", "--low-level-retries", "1",
                "--contimeout", Self.timeout, "--timeout", Self.lowLevelTimeout
            ], environment: environment(remote.environment), timeout: .seconds(20))
        } catch {
            throw AppError(String(localized: .couldNotCreateLinkUploading(redacted(error, credentials: credentials).localizedDescription)))
        }
        guard let link = URL(string: String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)),
              ["http", "https"].contains(link.scheme) else {
            throw AppError(String(localized: .couldNotCreateLink))
        }
        return link
    }
}

private extension MountService {
    func eject(_ connection: Connection, force: Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: Self.ejectRetryTime)
        while true {
            do {
                _ = try await Command.run(URL(filePath: "/sbin/umount"), (force ? ["-f"] : []) + [paths.mount(connection).path], timeout: .seconds(60))
                break
            } catch where ContinuousClock.now < deadline {
                try await Task.sleep(for: .seconds(1))
            } catch {
                throw AppError(String(localized: .couldNotEject(error.localizedDescription)))
            }
        }
        for _ in 0..<20 {
            if !isMounted(paths.mount(connection)) { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw AppError(String(localized: .driveStillMounted))
    }

    func stop(_ connection: Connection) async throws {
        var quitError: any Error = AppError(String(localized: .driveStillStopping))
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

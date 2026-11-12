import Darwin
import Foundation
import UnlocalFSDomain

enum RcloneState { case running, stopped, untracked }

public actor MountService: DriveGateway {
    let executable: URL
    private let helperDirectory: URL
    let paths: AppPaths
    let serverTrust: SFTPTrustStore
    private var processes: [UUID: Process] = [:]
    private var starting: Set<UUID> = []
    var reservedCopies: [UUID: Set<String>] = [:]
    let traffic: TrafficStore
    var trackers: [UUID: TrafficTracker] = [:]
    let googleClient: GoogleClient
    var signIns: [UUID: Task<Data, any Error>] = [:]

    public init(executable: URL, helperDirectory: URL, paths: AppPaths, traffic: TrafficStore, googleClient: GoogleClient) {
        self.executable = executable
        self.helperDirectory = helperDirectory
        self.paths = paths
        self.traffic = traffic
        self.googleClient = googleClient
        serverTrust = SFTPTrustStore(paths: paths)
    }

    public nonisolated func remoteFile(_ file: URL, among connections: [Connection]) -> (connection: Connection, path: String)? {
        paths.drive(containing: file, among: connections)
    }

    public nonisolated func removeCache(_ connection: Connection) { paths.removeCache(connection) }

    public func test(_ connection: Connection, credentials: Credentials) async throws {
        try requireGoogleSignIn(connection, credentials: credentials)
        let credentials = try await prepareCredentials(credentials)
        let remote = try await remote(for: connection, credentials: credentials)
        do {
            _ = try await runRemoteCommand(["lsf", connection.rcloneTarget, "--max-depth", "1", "--dirs-only", "--crypt-strict-names"], remote: remote)
        } catch {
            let failure = redacted(error, credentials: credentials)
            if isRevokedGrant(connection, failure.localizedDescription) { throw GoogleSignInRequired() }
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
        try requireGoogleSignIn(connection, credentials: credentials)
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
        let command = try await MountCommand(remote: remote(for: connection, credentials: credentials), paths: paths)
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
            try await serve(command, in: process)
        } catch {
            process.terminate()
            processes[connection.id] = nil
            throw redacted(error, credentials: credentials)
        }
    }

    public func status(_ connection: Connection) async -> MountStatus {
        var status = MountStatus()
        status.isMounted = isMounted(paths.mount(connection))
        let running = rcloneState(connection)
        status.isRunning = running == .running
        guard FileManager.default.fileExists(atPath: paths.socket(connection).path) else {
            if status.isActive {
                status.controlError = String(localized: .controlServiceUnavailableReconnect)
            }
            return status
        }
        if !status.isMounted, running == .running, !starting.contains(connection.id), await stopsAfterEject(connection) {
            return MountStatus()
        }
        do {
            let snapshot = try await snapshot(connection, ControlSnapshot.statusRequest)
            status.isRunning = true
            status.pendingUploads = snapshot.cache.uploadsQueued + snapshot.cache.uploadsInProgress
            status.failedUploads = snapshot.queue.count(where: \.hasFailedAttempt)
            if status.failedUploads > 0 { status.uploadError = snapshot.lastError }
            if isRevokedGrant(connection, status.uploadError), snapshot.queue.contains(where: { $0.hasFailedAttempt && !$0.uploading }) {
                status.needsSignIn = true
                status.uploadError = GoogleSignInRequired().localizedDescription
            }
            status.bytesCached = snapshot.cache.bytesUsed
            status.isDownloading = snapshot.transfers.contains { !$0.isUpload }
            let files = activeFiles(snapshot)
            status.uploadSpeed = files.bytesPerSecond(.uploading)
            status.downloadSpeed = files.bytesPerSecond(.downloading)
            status.unsavedTraffic = recordTraffic(snapshot, for: connection)
        } catch {
            if status.isMounted || running != .stopped {
                status.controlError = String(localized: .controlServiceUnavailable(error.localizedDescription))
            }
        }
        return status
    }

    public func activity(_ connection: Connection) async throws -> [FileActivity] {
        let snapshot = try await snapshot(connection, ControlSnapshot.activityRequest)
        let active = activeFiles(snapshot)
        let finished = snapshot.finished
            .filter { $0.error.isEmpty && ($0.isUpload || $0.bytes >= $0.size) }
            .map {
                FileActivity(path: $0.name, size: $0.size, state: $0.isUpload ? .uploaded($0.completedAt) : .downloaded($0.completedAt), bytesTransferred: $0.bytes)
            }
        let activeIDs = Set(active.map(\.id))
        let latestFinished = Dictionary(finished.map { ($0.id, $0) }) { _, later in later }.values.filter { !activeIDs.contains($0.id) }
        return active + latestFinished
    }

    private func activeFiles(_ snapshot: ControlSnapshot) -> [FileActivity] {
        let queuedPaths = Set(snapshot.queue.map(\.name))
        let uploadErrors = Dictionary(snapshot.finished.filter { $0.isUpload && !$0.error.isEmpty }.map { ($0.name, $0.error) }) { _, later in later }
        let queued = snapshot.queue.map { item in
            let state: FileActivity.State = item.uploading ? .uploading : item.hasFailedAttempt ? .failed(nextAttempt: .now + item.expiry) : .queued
            let transfer = item.uploading ? snapshot.transfers.first { $0.isUpload && $0.name == item.name } : nil
            return FileActivity(
                path: item.name, size: item.size, state: state, bytesTransferred: transfer?.bytes, bytesPerSecond: transfer?.speedAvg,
                uploadError: item.hasFailedAttempt ? uploadErrors[item.name] : nil,
            )
        }
        let transferring = snapshot.transfers.filter { !$0.isUpload || !queuedPaths.contains($0.name) }.map {
            FileActivity(path: $0.name, size: $0.size, state: $0.isUpload ? .uploading : .downloading, bytesTransferred: $0.bytes, bytesPerSecond: $0.speedAvg)
        }
        return queued + transferring
    }

    public func refresh(_ connection: Connection) async throws { _ = try await control(connection, "vfs/forget") }

    public func reconnect(_ connection: Connection, credentials: Credentials) async throws {
        try await unmount(connection)
        try await mount(connection, credentials: credentials)
    }

    public func unmount(_ connection: Connection) async throws {
        var current = await status(connection)
        if current.needsReconnect, rcloneState(connection) == .untracked {
            throw AppError(String(localized: .couldNotStopOldService))
        }
        let reachable = try await reachesControl(connection, updating: &current)
        try current.requireSafeDisconnect()
        try await requireNoCopies(connection, status: current)
        saveTraffic(connection)
        if current.isMounted { try await eject(connection, force: !current.isRunning || !reachable) }
        if current.needsReconnect {
            try await stop(connection, askingToQuit: reachable)
        } else if current.isRunning {
            let remaining = await status(connection)
            try remaining.requireSafeDisconnect()
            try await requireNoCopies(connection, status: remaining)
            saveTraffic(connection)
            if let error = remaining.controlError {
                guard try await waitForStop(connection) else { throw AppError(error) }
            } else if remaining.isRunning {
                try await stop(connection, askingToQuit: true)
            }
        }
        processes[connection.id] = nil
        trackers[connection.id] = nil
        let pidFile = paths.pidFile(connection)
        if FileManager.default.fileExists(atPath: pidFile.path) { try FileManager.default.removeItem(at: pidFile) }
    }

    func control(
        _ connection: Connection, _ method: String, _ parameters: [String: String] = [:], timeout: Duration = .seconds(4),
    ) async throws -> Data {
        try await control(connection, method, body: JSONEncoder().encode(parameters), timeout: timeout)
    }

    func control(_ connection: Connection, _ method: String, body: Data, timeout: Duration = .seconds(4)) async throws -> Data {
        try await ControlSocket.post(paths.socket(connection), method, body: body, timeout: timeout)
    }

    func control<Response: Decodable>(
        _ response: Response.Type, _ connection: Connection, _ method: String, _ parameters: [String: String] = [:],
    ) async throws -> Response {
        try await JSONDecoder().decode(response, from: control(connection, method, parameters))
    }

    private func snapshot(_ connection: Connection, _ request: String) async throws -> ControlSnapshot {
        try await JSONDecoder().decode(ControlSnapshot.self, from: control(connection, "job/batch", body: Data(request.utf8)))
    }

    func rcloneState(_ connection: Connection) -> RcloneState {
        guard let pid = savedPID(connection) else { return processes[connection.id].map { $0.isRunning ? .running : .stopped } ?? .untracked }
        if let process = processes[connection.id], process.processIdentifier == pid { return process.isRunning ? .running : .stopped }
        let saved = try? paths.pidFile(connection).resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        guard let process = Self.process(pid: pid), let saved else { return .stopped }
        return process.startedAt <= saved ? .running : .stopped
    }

    func requireServing(_ connection: Connection, otherwise message: LocalizedStringResource) throws {
        guard isMounted(paths.mount(connection)), FileManager.default.fileExists(atPath: paths.socket(connection).path) else {
            throw AppError(String(localized: message))
        }
    }

    func isWaitingToUpload(_ path: String, in connection: Connection) async throws -> Bool {
        try await control(UploadQueue.self, connection, "vfs/queue").queue.contains { $0.name == path }
    }

    func runRemoteCommand(_ arguments: [String], remote: RcloneRemote) async throws -> Data {
        try await Command.run(executable, arguments + [
            "--config", "/dev/null", "--retries", "1", "--low-level-retries", "1", "--contimeout", "5s", "--timeout", "10s",
        ], environment: environment(remote.environment), timeout: .seconds(20))
    }

    var baseEnvironment: [String: String] { [
        "HOME": URL.homeDirectory.path,
        "PATH": "\(helperDirectory.path):/usr/bin:/bin:/usr/sbin:/sbin",
        "TMPDIR": URL.temporaryDirectory.path,
        "LANG": "en_US.UTF-8",
    ]
    }

    func environment(_ variables: [String: String]) -> [String: String] {
        baseEnvironment.merging(variables) { _, new in new }
    }

    func remote(for connection: Connection, credentials: Credentials?) async throws -> RcloneRemote {
        switch connection.backend {
        case .s3Compatible, .gcs:
            return RcloneRemote(connection: connection, credentials: credentials, knownHosts: paths.knownHosts, googleClient: googleClient)
        case .sftp:
            let sftp = connection.sftp
            let knownHosts = try await serverTrust.file()
            if sftp.authentication == .privateKey { try requireReadableFile(sftp.keyPath, failure: { .cannotReadPrivateKeyFile($0) }) }
            let socket = sftp.authentication == .agent ? try agentSocket(sftp) : nil
            return RcloneRemote(connection: connection, credentials: credentials, knownHosts: knownHosts, googleClient: googleClient, agentSocket: socket)
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
        let path = sftp.agentSocket.isEmpty ? ProcessInfo.processInfo.environment["SSH_AUTH_SOCK"] : sftp.agentSocketPath
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
            credentials.serviceAccountKey, credentials.googleToken,
        ] + (GoogleToken(json: credentials.googleToken).map { [$0.accessToken, $0.refreshToken] } ?? [])
        for secret in secrets where !secret.isEmpty {
            message = message.replacingOccurrences(of: secret, with: "[redacted]")
        }
        return AppError(message)
    }

    func isMounted(_ url: URL) -> Bool {
        guard let parent = realpath(url.deletingLastPathComponent().path, nil) else { return false }
        defer { free(parent) }
        let path = URL(filePath: String(cString: parent)).appending(path: url.lastPathComponent).path
        var mounts: UnsafeMutablePointer<statfs>?
        let count = getmntinfo_r_np(&mounts, MNT_NOWAIT)
        guard let mounts else { return false }
        defer { free(mounts) }
        return (0 ..< Int(count)).contains { index in
            withUnsafePointer(to: mounts[index].f_mntonname) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { String(cString: $0) == path }
            }
        }
    }
}

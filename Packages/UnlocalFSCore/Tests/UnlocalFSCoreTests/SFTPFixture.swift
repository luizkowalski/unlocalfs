import Darwin
import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

enum SFTPLogin: CaseIterable {
    case password, key, protectedKey, agent
}

struct SFTPFixture {
    static let password = "sftp-secret"
    static let passphrase = "key passphrase"

    let port: Int
    let root: URL
    let executable: URL
    let keys: URL
    let knownHosts: URL
    let agent: SSHAgent
    let emptyAgent: SSHAgent
    var server: SFTPServer

    var served: URL { root.appending(path: "source") }
    var key: URL { keys.appending(path: "client") }
    var protectedKey: URL { keys.appending(path: "client-protected") }

    init(executable: URL, root: URL) async throws {
        let port = try freePort()
        self.port = port
        self.root = root
        self.executable = executable
        let keys = root.appending(path: "keys")
        let knownHosts = root.appending(path: "known_hosts")
        try FileManager.default.createDirectory(at: keys, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appending(path: "source"), withIntermediateDirectories: true)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (name, passphrase) in [("host", ""), ("client", ""), ("client-protected", Self.passphrase), ("other-host", "")] {
                group.addTask { try await Self.generateKey(keys.appending(path: name), passphrase: passphrase) }
            }
            try await group.waitForAll()
        }
        let authorized = try ["client", "client-protected"].map { try Self.publicKey(keys.appending(path: $0)) }
        try Data((authorized.joined(separator: "\n") + "\n").utf8).write(to: root.appending(path: "authorized_keys"))
        try Data("[127.0.0.1]:\(port) \(try Self.publicKey(keys.appending(path: "host")))\n".utf8).write(to: knownHosts)
        self.keys = keys
        self.knownHosts = knownHosts
        async let startedAgent = SSHAgent(socket: root.appending(path: "agent.sock"), keys: [keys.appending(path: "client")])
        async let startedEmptyAgent = SSHAgent(socket: root.appending(path: "empty-agent.sock"), keys: [])
        async let startedServer = SFTPServer(executable: executable, root: root, hostKey: keys.appending(path: "host"), port: port)
        agent = try await startedAgent
        emptyAgent = try await startedEmptyAgent
        server = try await startedServer
    }

    mutating func restartServer(hostKey name: String) async throws {
        server.stop()
        server = try await SFTPServer(executable: executable, root: root, hostKey: keys.appending(path: name), port: port)
    }

    func stop() {
        server.stop()
        agent.stop()
        emptyAgent.stop()
    }

    func connection(_ login: SFTPLogin, folder: String = "", encrypted: Bool = false, readOnly: Bool = false) -> Connection {
        var connection = sftpFixture()
        connection.sftp.host = "127.0.0.1"
        connection.sftp.port = port
        connection.sftp.username = "test"
        connection.sftp.remotePath = folder
        connection.sftp.trustedHostsFile = knownHosts.path
        connection.encrypted = encrypted
        connection.readOnly = readOnly
        switch login {
        case .password:
            connection.sftp.authentication = .password
        case .key:
            connection.sftp.authentication = .privateKey
            connection.sftp.keyFile = key.path
        case .protectedKey:
            connection.sftp.authentication = .privateKey
            connection.sftp.keyFile = protectedKey.path
        case .agent:
            connection.sftp.authentication = .agent
            connection.sftp.agentSocket = agent.socket.path
        }
        return connection
    }

    func credentials(_ login: SFTPLogin, encryptionPassword: String = "") -> Credentials {
        Credentials(
            encryptionPassword: encryptionPassword,
            password: login == .password ? Self.password : "",
            keyPassphrase: login == .protectedKey ? Self.passphrase : ""
        )
    }

    private static func generateKey(_ file: URL, passphrase: String) async throws {
        _ = try await Command.run(URL(filePath: "/usr/bin/ssh-keygen"), ["-q", "-t", "ed25519", "-a", "1", "-N", passphrase, "-C", "", "-f", file.path])
    }

    private static func publicKey(_ file: URL) throws -> String {
        let line = try String(contentsOf: file.appendingPathExtension("pub"), encoding: .utf8)
        return line.split(separator: " ").prefix(2).joined(separator: " ")
    }
}

struct SFTPServer {
    let process = Process()
    let log: FileHandle

    init(executable: URL, root: URL, hostKey: URL, port: Int) async throws {
        let logURL = root.appending(path: "sftp-server.log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        log = try FileHandle(forWritingTo: logURL)
        process.executableURL = executable
        process.arguments = [
            "serve", "sftp", root.appending(path: "source").path, "--addr", "127.0.0.1:\(port)",
            "--user", "test", "--pass", SFTPFixture.password, "--authorized-keys", root.appending(path: "authorized_keys").path,
            "--key", hostKey.path, "--dir-cache-time", "0s", "--config", "/dev/null"
        ]
        process.standardOutput = log
        process.standardError = log
        try process.run()
        let serving = { (try? String(contentsOf: logURL, encoding: .utf8))?.contains("listening") ?? false }
        for _ in 0..<500 where process.isRunning && !serving() {
            try await Task.sleep(for: .milliseconds(20))
        }
        if !serving() { process.terminate() }
        try #require(
            process.isRunning && serving(),
            "SFTP fixture could not start: \((try? String(contentsOf: logURL, encoding: .utf8)) ?? "")"
        )
    }

    func stop() {
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        try? log.close()
    }
}

struct SSHAgent {
    let process = Process()
    let socket: URL

    init(socket: URL, keys: [URL]) async throws {
        self.socket = socket
        process.executableURL = URL(filePath: "/usr/bin/ssh-agent")
        process.arguments = ["-D", "-a", socket.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        for _ in 0..<500 where !FileManager.default.fileExists(atPath: socket.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        for key in keys {
            _ = try await Command.run(URL(filePath: "/usr/bin/ssh-add"), [key.path], environment: ["SSH_AUTH_SOCK": socket.path])
        }
    }

    func stop() {
        if process.isRunning { process.terminate() }
    }
}

func withSFTPDrive(
    _ login: SFTPLogin = .password, folder: String = "", encrypted: Bool = false, readOnly: Bool = false,
    _ body: (Drive, inout SFTPFixture) async throws -> Void
) async throws {
    let executable = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["RCLONE_BINARY"]))
    let root = URL(fileURLWithPath: "/tmp/uf-\(UUID().uuidString.prefix(8))")
    var sftp = try await SFTPFixture(executable: executable, root: root)
    defer { sftp.stop() }
    let paths = AppPaths(
        config: root.appending(path: "config.json"), support: root.appending(path: "app"),
        mounts: root.appending(path: "drives"), logs: root.appending(path: "logs")
    )
    let connection = sftp.connection(login, folder: folder, encrypted: encrypted, readOnly: readOnly)
    let drive = Drive(
        executable: executable, bucket: sftp.served, paths: paths,
        service: MountService(executable: executable, helperDirectory: helpers, paths: paths), connection: connection
    )
    do {
        try await body(drive, &sftp)
    } catch {
        await drive.disconnect()
        throw error
    }
    await drive.disconnect()
    try FileManager.default.removeItem(at: root)
}

func freePort() throws -> Int {
    let descriptor = socket(AF_INET, SOCK_STREAM, 0)
    defer { close(descriptor) }
    var address = sockaddr_in()
    address.sin_family = sa_family_t(AF_INET)
    address.sin_addr.s_addr = inet_addr("127.0.0.1")
    let size = socklen_t(MemoryLayout<sockaddr_in>.size)
    let bound = withUnsafePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(descriptor, $0, size) } }
    try #require(bound == 0)
    var length = size
    _ = withUnsafeMutablePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(descriptor, $0, &length) } }
    return Int(UInt16(bigEndian: address.sin_port))
}

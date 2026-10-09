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

    let login: SFTPLogin
    let port: Int
    let root: URL
    let executable: URL
    let keys: URL
    let knownHostsEntry: String
    let resources: FixtureResources
    var server: SFTPServer

    var agentSocket: URL { root.appending(path: "agent.sock") }
    var served: URL { root.appending(path: "source") }
    var key: URL { keys.appending(path: "client") }
    var protectedKey: URL { keys.appending(path: "client-protected") }

    init(executable: URL, resources: FixtureResources, login: SFTPLogin) async throws {
        let root = resources.root
        self.login = login
        self.root = root
        self.executable = executable
        self.resources = resources
        let keys = root.appending(path: "keys")
        try FileManager.default.createDirectory(at: keys, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appending(path: "source"), withIntermediateDirectories: true)
        var keyNames = [("host", "")]
        if login == .key || login == .agent { keyNames.append(("client", "")) }
        if login == .protectedKey { keyNames.append(("client-protected", Self.passphrase)) }
        for (name, passphrase) in keyNames { try await Self.generateKey(keys.appending(path: name), passphrase: passphrase) }
        let authorized = try keyNames.filter { $0.0 != "host" }.map { try Self.publicKey(keys.appending(path: $0.0)) }
        try Data(authorized.joined(separator: "\n").utf8).write(to: root.appending(path: "authorized_keys"))
        self.keys = keys
        if login == .agent {
            try await startAgent(resources: resources, socket: root.appending(path: "agent.sock"), key: keys.appending(path: "client"))
        }
        let server = try await SFTPServer(executable: executable, resources: resources, hostKey: keys.appending(path: "host"))
        self.server = server
        port = server.port
        knownHostsEntry = "[127.0.0.1]:\(server.port) \(try Self.publicKey(keys.appending(path: "host")))\n"
    }

    mutating func restartServer(hostKey name: String) async throws {
        try await resources.stop(server.process)
        let key = keys.appending(path: name)
        if !FileManager.default.fileExists(atPath: key.path) { try await Self.generateKey(key, passphrase: "") }
        server = try await SFTPServer(executable: executable, resources: resources, hostKey: key, port: port)
    }

    var connection: Connection {
        var connection = sftpFixture()
        connection.sftp.host = "127.0.0.1"
        connection.sftp.port = port
        connection.sftp.username = "test"
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
            connection.sftp.agentSocket = agentSocket.path
        }
        return connection
    }

    var credentials: Credentials {
        Credentials(password: login == .password ? Self.password : "", keyPassphrase: login == .protectedKey ? Self.passphrase : "")
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
    let process: Process
    let port: Int

    init(executable: URL, resources: FixtureResources, hostKey: URL, port: Int = 0) async throws {
        let root = resources.root
        let authorized = root.appending(path: "authorized_keys")
        let authorizedPath = try Data(contentsOf: authorized).isEmpty ? "" : authorized.path
        let process = try await resources.start(executable, arguments: [
            "serve", "sftp", root.appending(path: "source").path, "--addr", "127.0.0.1:\(port)",
            "--user", "test", "--pass", SFTPFixture.password, "--authorized-keys", authorizedPath,
            "--key", hostKey.path, "--dir-cache-time", "0s", "--config", "/dev/null"
        ], log: "sftp-server.log")
        let listening = try await requireOutput(of: process, in: resources, matching: #/SFTP server listening on 127\.0\.0\.1:(\d+)/#)
        self.process = process
        self.port = try #require(Int(listening))
    }
}

private func startAgent(resources: FixtureResources, socket: URL, key: URL) async throws {
    let process = try await resources.start(URL(filePath: "/usr/bin/ssh-agent"), arguments: ["-D", "-a", socket.path], log: "agent.log")
    try await requireOutput(of: process, in: resources, matching: #/Agent pid (\d+)/#)
    _ = try await Command.run(URL(filePath: "/usr/bin/ssh-add"), [key.path], environment: ["SSH_AUTH_SOCK": socket.path])
}

func withSFTPDrive(
    _ login: SFTPLogin = .password, trusted: Bool = true, _ body: (Drive, inout SFTPFixture) async throws -> Void
) async throws {
    let executable = try await rcloneExecutable.value
    try await withFixture { resources in
        var sftp = try await SFTPFixture(executable: executable, resources: resources, login: login)
        let drive = await makeDrive(executable: executable, resources: resources, connection: sftp.connection)
        if trusted {
            try drive.paths.prepare()
            try Data(sftp.knownHostsEntry.utf8).write(to: drive.knownHosts)
        }
        try await body(drive, &sftp)
    }
}

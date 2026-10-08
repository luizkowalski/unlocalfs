import Darwin
import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

enum SFTPLogin: CaseIterable, Hashable {
    case password, key, protectedKey, agent
}

struct SFTPFixture {
    static let password = "sftp-secret"
    static let passphrase = "key passphrase"

    let port: Int
    let root: URL
    let executable: URL
    let keys: URL
    let knownHostsEntry: String
    let resources: FixtureResources
    var server: SFTPServer

    var agentSocket: URL { root.appending(path: "agent.sock") }
    var emptyAgentSocket: URL { root.appending(path: "empty-agent.sock") }
    var served: URL { root.appending(path: "source") }
    var key: URL { keys.appending(path: "client") }
    var protectedKey: URL { keys.appending(path: "client-protected") }

    init(executable: URL, resources: FixtureResources, logins: [SFTPLogin], emptyAgent: Bool) async throws {
        let port = try freePort()
        let root = resources.root
        self.port = port
        self.root = root
        self.executable = executable
        self.resources = resources
        let keys = root.appending(path: "keys")
        try FileManager.default.createDirectory(at: keys, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appending(path: "source"), withIntermediateDirectories: true)
        var keyNames = [("host", "")]
        if logins.contains(.key) || logins.contains(.agent) { keyNames.append(("client", "")) }
        if logins.contains(.protectedKey) { keyNames.append(("client-protected", Self.passphrase)) }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (name, passphrase) in keyNames {
                group.addTask { try await Self.generateKey(keys.appending(path: name), passphrase: passphrase) }
            }
            try await group.waitForAll()
        }
        let authorized = try keyNames.filter { $0.0 != "host" }.map { try Self.publicKey(keys.appending(path: $0.0)) }
        try Data(authorized.joined(separator: "\n").utf8).write(to: root.appending(path: "authorized_keys"))
        self.keys = keys
        knownHostsEntry = "[127.0.0.1]:\(port) \(try Self.publicKey(keys.appending(path: "host")))\n"
        if logins.contains(.agent) {
            try await startAgent(resources: resources, socket: root.appending(path: "agent.sock"), keys: [keys.appending(path: "client")])
        }
        if emptyAgent {
            try await startAgent(resources: resources, socket: root.appending(path: "empty-agent.sock"), keys: [])
        }
        server = try await SFTPServer(executable: executable, resources: resources, hostKey: keys.appending(path: "host"), port: port)
    }

    mutating func restartServer(hostKey name: String) async throws {
        try await resources.stop(server.process)
        let key = keys.appending(path: name)
        if !FileManager.default.fileExists(atPath: key.path) { try await Self.generateKey(key, passphrase: "") }
        server = try await SFTPServer(executable: executable, resources: resources, hostKey: key, port: port)
    }

    func connection(_ login: SFTPLogin, folder: String = "", encrypted: Bool = false, readOnly: Bool = false) -> Connection {
        var connection = sftpFixture()
        connection.sftp.host = "127.0.0.1"
        connection.sftp.port = port
        connection.sftp.username = "test"
        connection.sftp.remotePath = folder
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
            connection.sftp.agentSocket = agentSocket.path
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

    static func publicKey(_ file: URL) throws -> String {
        let line = try String(contentsOf: file.appendingPathExtension("pub"), encoding: .utf8)
        return line.split(separator: " ").prefix(2).joined(separator: " ")
    }
}

struct SFTPServer {
    let process: Process

    init(executable: URL, resources: FixtureResources, hostKey: URL, port: Int) async throws {
        let root = resources.root
        let hosts = root.appending(path: "readiness_known_hosts")
        try "[127.0.0.1]:\(port) \(SFTPFixture.publicKey(hostKey))\n".write(to: hosts, atomically: true, encoding: .utf8)
        let password = try await Command.run(executable, ["obscure", "-", "--config", "/dev/null"], input: SFTPFixture.password)
        let authorized = root.appending(path: "authorized_keys")
        let authorizedPath = try Data(contentsOf: authorized).isEmpty ? "" : authorized.path
        process = try await resources.start(executable, arguments: [
            "serve", "sftp", root.appending(path: "source").path, "--addr", "127.0.0.1:\(port)",
            "--user", "test", "--pass", SFTPFixture.password, "--authorized-keys", authorizedPath,
            "--key", hostKey.path, "--dir-cache-time", "0s", "--config", "/dev/null"
        ], log: "sftp-server.log")
        let environment = [
            "RCLONE_SFTP_HOST": "127.0.0.1", "RCLONE_SFTP_PORT": "\(port)", "RCLONE_SFTP_USER": "test",
            "RCLONE_SFTP_PASS": String(decoding: password, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines),
            "RCLONE_SFTP_KNOWN_HOSTS_FILE": hosts.path, "RCLONE_SFTP_SHELL_TYPE": "none"
        ]
        try await requireReady(process, log: root.appending(path: "sftp-server.log")) {
            _ = try await Command.run(executable, [
                "lsf", ":sftp:", "--config", "/dev/null", "--retries", "1", "--low-level-retries", "1"
            ], environment: environment, timeout: .seconds(2))
        }
    }
}

private func startAgent(resources: FixtureResources, socket: URL, keys: [URL]) async throws {
    let process = try await resources.start(URL(filePath: "/usr/bin/ssh-agent"), arguments: ["-D", "-a", socket.path], log: socket.lastPathComponent + ".log")
    try await requireReady(process, log: socket.appendingPathExtension("log")) {
        _ = try await Command.run(URL(filePath: "/usr/bin/ssh-add"), ["-D"], environment: ["SSH_AUTH_SOCK": socket.path], timeout: .seconds(1))
    }
    for key in keys {
        _ = try await Command.run(URL(filePath: "/usr/bin/ssh-add"), [key.path], environment: ["SSH_AUTH_SOCK": socket.path])
    }
}

func withSFTPDrive(
    _ login: SFTPLogin = .password, folder: String = "", encrypted: Bool = false, readOnly: Bool = false, trusted: Bool = true,
    additionalLogins: [SFTPLogin] = [], emptyAgent: Bool = false,
    _ body: (Drive, inout SFTPFixture) async throws -> Void
) async throws {
    let executable = try await rcloneExecutable.value
    try await withFixture { resources in
        var sftp = try await SFTPFixture(executable: executable, resources: resources, logins: [login] + additionalLogins, emptyAgent: emptyAgent)
        let connection = sftp.connection(login, folder: folder, encrypted: encrypted, readOnly: readOnly)
        let drive = await makeDrive(executable: executable, bucket: sftp.served, resources: resources, connection: connection)
        if trusted {
            try drive.paths.prepare()
            try Data(sftp.knownHostsEntry.utf8).write(to: drive.knownHosts)
        }
        try await body(drive, &sftp)
    }
}

extension Drive {
    var knownHosts: URL { paths.support.appending(path: "known_hosts") }
}

func unixAddress(_ url: URL) -> sockaddr_un {
    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    _ = withUnsafeMutableBytes(of: &address.sun_path) { buffer in
        url.path.withCString { strlcpy(buffer.baseAddress!.assumingMemoryBound(to: CChar.self), $0, buffer.count) }
    }
    return address
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

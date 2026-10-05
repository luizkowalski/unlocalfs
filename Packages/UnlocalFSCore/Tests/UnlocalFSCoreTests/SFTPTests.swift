import Darwin
import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure

@Suite(.timeLimit(.minutes(2)))
struct SFTPTests {
    @Test(arguments: SFTPLogin.allCases)
    func sftpDriveAuthenticatesReadsAndWrites(login: SFTPLogin) async throws {
        try await withSFTPDrive(login) { drive, sftp in
            try Data("hello from SFTP".utf8).write(to: sftp.served.appending(path: "hello.txt"))
            let credentials = sftp.credentials(login)
            try await drive.service.test(drive.connection, credentials: credentials)
            try await drive.service.mount(drive.connection, credentials: credentials)
            #expect(try String(contentsOf: drive.mounted.appending(path: "hello.txt"), encoding: .utf8) == "hello from SFTP")
            try Data("written through Finder's filesystem".utf8).write(to: drive.mounted.appending(path: "upload.txt"))
            try await drive.waitForUploads(on: drive.service)
            #expect(try String(contentsOf: sftp.served.appending(path: "upload.txt"), encoding: .utf8) == "written through Finder's filesystem")
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test func sftpRejectsWrongCredentials() async throws {
        try await withSFTPDrive { drive, sftp in
            await #expect(throws: AppError.self) {
                try await drive.service.test(drive.connection, credentials: Credentials(password: "wrong"))
            }
            var connection = sftp.connection(.protectedKey)
            await #expect {
                try await drive.service.test(connection, credentials: Credentials())
            } throws: { $0.localizedDescription.contains("passphrase") }
            connection.sftp.keyFile = sftp.key.path
            try await drive.service.test(connection, credentials: Credentials())
        }
    }

    @Test(arguments: ["unknown", "changed"])
    func sftpRefusesUntrustedServersAndLeavesTrustUntouched(trust: String) async throws {
        try await withSFTPDrive { drive, sftp in
            var connection = drive.connection
            if trust == "unknown" {
                connection.sftp.trustedHostsFile = sftp.root.appending(path: "empty_hosts").path
                try Data().write(to: URL(filePath: connection.sftp.trustedHostsFile))
            } else {
                try await sftp.restartServer(hostKey: "other-host")
            }
            let trustedHosts = URL(filePath: connection.sftp.trustedHostsFile)
            let before = try Data(contentsOf: trustedHosts)
            let credentials = sftp.credentials(.password)
            let expected = trust == "unknown"
                ? String(localized: .hostKeyNotTrusted(trustedHosts.path, ""))
                : String(localized: .hostKeyChanged(trustedHosts.path, ""))

            for attempt in [{ try await drive.service.test(connection, credentials: credentials) },
                            { try await drive.service.mount(connection, credentials: credentials) }] {
                await #expect {
                    try await attempt()
                } throws: { $0.localizedDescription.hasPrefix(expected) }
            }

            #expect(try Data(contentsOf: trustedHosts) == before)
            #expect(await !drive.service.status(connection).isActive)
        }
    }

    @Test(arguments: ["", "clients/acme", "/clients/acme"])
    func sftpFoldersAddressTheServerDirectory(folder: String) async throws {
        try await withSFTPDrive(.key, folder: folder) { drive, sftp in
            let directory = sftp.served.appending(path: "clients/acme")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("acme plan".utf8).write(to: directory.appending(path: "plan.txt"))
            try Data("root file".utf8).write(to: sftp.served.appending(path: "root.txt"))
            try await drive.service.mount(drive.connection, credentials: Credentials())
            let expected = folder.isEmpty ? ["clients", "root.txt"] : ["plan.txt"]
            #expect(try FileManager.default.contentsOfDirectory(atPath: drive.mounted.path).sorted() == expected)
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test func encryptedSFTPDriveUploadsOnlyCiphertextAndRejectsTheWrongPassword() async throws {
        try await withSFTPDrive(.password, encrypted: true) { drive, sftp in
            let credentials = sftp.credentials(.password, encryptionPassword: "correct horse")
            try await drive.service.mount(drive.connection, credentials: credentials)
            try Data("top secret".utf8).write(to: drive.mounted.appending(path: "secret plan.txt"))
            try await drive.waitForUploads(on: drive.service)
            try await drive.service.unmount(drive.connection)
            let stored = try FileManager.default.subpathsOfDirectory(atPath: sftp.served.path)
            #expect(stored.count == 1)
            #expect(try #require(stored.first).contains("secret") == false)
            #expect(try !String(decoding: Data(contentsOf: sftp.served.appending(path: stored[0])), as: UTF8.self).contains("top secret"))
            try FileManager.default.removeItem(at: drive.paths.cache(drive.connection))
            try await drive.service.mount(drive.connection, credentials: credentials)
            #expect(try String(contentsOf: drive.mounted.appending(path: "secret plan.txt"), encoding: .utf8) == "top secret")
            try await drive.service.unmount(drive.connection)
            var wrong = credentials
            wrong.encryptionPassword = "wrong"
            await #expect { try await drive.service.test(drive.connection, credentials: wrong) } throws: {
                $0.localizedDescription.contains("undecryptable")
            }
        }
    }

    @Test func runningSFTPDriveKeepsSecretsOutOfProcessArgumentsAndLogs() async throws {
        try await withSFTPDrive(.protectedKey, encrypted: true) { drive, sftp in
            let credentials = try await drive.service.prepareCredentials(sftp.credentials(.protectedKey, encryptionPassword: "correct horse"))
            try await drive.service.mount(drive.connection, credentials: credentials)
            let pid = try #require(try await drive.control("core/pid")["pid"] as? Int)
            let arguments = try await Command.run(URL(filePath: "/bin/ps"), ["-ww", "-o", "args=", "-p", "\(pid)"])
            try await drive.service.unmount(drive.connection)
            let log = try String(contentsOf: drive.paths.log(drive.connection), encoding: .utf8)
            let secrets = [
                SFTPFixture.passphrase, "correct horse", credentials.obscuredKeyPassphrase, credentials.obscuredEncryptionPassword
            ]
            for secret in secrets {
                #expect(!secret.isEmpty)
                #expect(!String(decoding: arguments, as: UTF8.self).contains(secret))
                #expect(!log.contains(secret))
            }
        }
    }
}

@Suite(.timeLimit(.minutes(2)))
struct SFTPAgentEnvironmentTests {
    @Test func agentSocketOverrideTakesPrecedenceOverTheEnvironment() async throws {
        try await withSFTPDrive(.agent) { drive, sftp in
            let service = drive.service(environment: ["SSH_AUTH_SOCK": sftp.agent.socket.path])
            var connection = drive.connection
            connection.sftp.agentSocket = ""
            try await service.test(connection, credentials: Credentials())
            connection.sftp.agentSocket = sftp.emptyAgent.socket.path
            await #expect(throws: AppError.self) {
                try await service.test(connection, credentials: Credentials(password: SFTPFixture.password))
            }
        }
    }

    @Test(arguments: ["missing", "stale", "unset"])
    func unavailableAgentFailsClearly(kind: String) async throws {
        try await withSFTPDrive(.agent) { drive, sftp in
            var connection = drive.connection
            let socket = sftp.root.appending(path: "stale.sock")
            try Self.leaveStaleSocket(at: socket)
            connection.sftp.agentSocket = kind == "missing" ? sftp.root.appending(path: "none.sock").path : kind == "stale" ? socket.path : ""
            let service = drive.service(environment: [:])
            for attempt in [{ try await service.test(connection, credentials: Credentials()) },
                            { try await service.mount(connection, credentials: Credentials()) }] {
                await #expect { try await attempt() } throws: { $0.localizedDescription.contains("ssh-agent") }
            }
            #expect(await !service.status(connection).isActive)
        }
    }

    private static func leaveStaleSocket(at url: URL) throws {
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        defer { close(descriptor) }
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        _ = withUnsafeMutableBytes(of: &address.sun_path) { buffer in
            url.path.withCString { strlcpy(buffer.baseAddress!.assumingMemoryBound(to: CChar.self), $0, buffer.count) }
        }
        let result = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
        try #require(result == 0)
    }
}

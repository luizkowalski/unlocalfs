import Darwin
import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure

extension IntegrationTests {
    @Suite
    struct SFTPTests {
        @Test(arguments: SFTPLogin.allCases)
        func encryptedSFTPDriveReadsWritesKeepsSecretsPrivateAndExportsARecoverableConfig(login: SFTPLogin) async throws {
            try await withSFTPDrive(login, encrypted: true) { drive, sftp in
                try await writeEncrypted("hello from SFTP", named: "hello.txt", to: sftp.served, executable: drive.executable)
                let credentials = try await drive.service.prepareCredentials(
                    sftp.credentials(login, encryptionPassword: encryptedDriveCredentials.encryptionPassword))
                try await drive.service.test(drive.connection, credentials: credentials)
                try await drive.service.mount(drive.connection, credentials: credentials)
                #expect(try String(contentsOf: drive.mounted.appending(path: "hello.txt"), encoding: .utf8) == "hello from SFTP")
                try Data("top secret".utf8).write(to: drive.mounted.appending(path: "secret plan.txt"))
                try await drive.waitForUploads(on: drive.service)
                let vfs = try #require(try await drive.control("options/get")["vfs"] as? [String: Any])
                #expect(vfs["ChunkStreams"] as? Int64 == 0, "an SFTP drive reads in one stream")
                let pid = try #require(try await drive.control("core/pid")["pid"] as? Int)
                let arguments = String(decoding: try await Command.run(URL(filePath: "/bin/ps"), ["-ww", "-o", "args=", "-p", "\(pid)"]), as: UTF8.self)
                try await drive.service.unmount(drive.connection)

                let stored = try FileManager.default.subpathsOfDirectory(atPath: sftp.served.path)
                #expect(stored.count == 2)
                #expect(!stored.contains { $0.contains("secret") || $0.contains("hello") }, "uploads only encrypted names")
                for file in stored {
                    #expect(try !String(decoding: Data(contentsOf: sftp.served.appending(path: file)), as: UTF8.self).contains("top secret"))
                }
                let log = try String(contentsOf: drive.paths.log(drive.connection), encoding: .utf8)
                let secrets = [
                    credentials.password, credentials.obscuredPassword, credentials.keyPassphrase, credentials.obscuredKeyPassphrase,
                    credentials.encryptionPassword, credentials.obscuredEncryptionPassword
                ].filter { !$0.isEmpty }
                #expect(secrets.count >= 2)
                for secret in secrets {
                    #expect(!arguments.contains(secret), "keeps secrets out of process arguments")
                    #expect(!log.contains(secret), "keeps secrets out of the log")
                }

                let config = sftp.root.appending(path: "My files rclone.conf")
                try await drive.service.exportRcloneConfig(drive.connection, credentials: credentials, to: config)
                let environment = login == .agent ? ["SSH_AUTH_SOCK": sftp.agentSocket.path] : [:]
                #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt", environment: environment) == "top secret")
                let remote = try #require(try await dump(drive, config)["unlocalfs-sftp"])
                #expect(remote["shell_type"] == "none" && remote["known_hosts_file"] == drive.knownHosts.path)
                #expect(remote["port"] == "\(sftp.port)" && remote["user"] == "test" && remote["host"] == "127.0.0.1")
            }
        }

        @Test func sftpRejectsWrongCredentials() async throws {
            try await withSFTPDrive(additionalLogins: [.key, .protectedKey]) { drive, sftp in
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
    }

    @Suite
    struct SFTPAgentEnvironmentTests {
        @Test func agentSocketOverrideTakesPrecedenceOverTheEnvironment() async throws {
            try await withSFTPDrive(.agent, emptyAgent: true) { drive, sftp in
                let service = drive.service(environment: ["SSH_AUTH_SOCK": sftp.agentSocket.path])
                var connection = drive.connection
                connection.sftp.agentSocket = ""
                try await service.test(connection, credentials: Credentials())
                connection.sftp.agentSocket = sftp.emptyAgentSocket.path
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
}

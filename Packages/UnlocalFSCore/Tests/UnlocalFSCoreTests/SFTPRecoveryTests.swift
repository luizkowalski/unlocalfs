import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

extension IntegrationTests {
    @Suite
    struct SFTPRecoveryTests {
        @Test(arguments: [SFTPLogin.password, .key, .protectedKey, .agent])
        func exportedConfigReadsFilesUploadedThroughAnEncryptedSFTPDrive(login: SFTPLogin) async throws {
            try await withSFTPDrive(login, encrypted: true) { drive, sftp in
                let credentials = try await drive.service.prepareCredentials(sftp.credentials(login, encryptionPassword: encryptedDriveCredentials.encryptionPassword))
                try await drive.service.mount(drive.connection, credentials: credentials)
                try Data("top secret".utf8).write(to: drive.mounted.appending(path: "secret plan.txt"))
                try await drive.waitForUploads(on: drive.service)
                try await drive.service.unmount(drive.connection)
                let config = sftp.root.appending(path: "My files rclone.conf")

                try await drive.service.exportRcloneConfig(drive.connection, credentials: credentials, to: config)

                let environment = login == .agent ? ["SSH_AUTH_SOCK": sftp.agentSocket.path] : [:]
                #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt", environment: environment) == "top secret")
                let remote = try #require(try await dump(drive, config)["unlocalfs-sftp"])
                #expect(remote["shell_type"] == "none" && remote["known_hosts_file"] == drive.knownHosts.path)
                #expect(remote["port"] == "\(sftp.port)" && remote["user"] == "test" && remote["host"] == "127.0.0.1")
            }
        }

        @Test(arguments: [SFTPLogin.password, .protectedKey, .agent])
        func exportedSFTPConfigWithoutSecretsRecoversOnceCredentialsAreSupplied(login: SFTPLogin) async throws {
            try await withSFTPDrive(login, encrypted: true) { drive, sftp in
                try await writeEncrypted("top secret", named: "secret plan.txt", to: sftp.served, executable: drive.executable)
                let config = sftp.root.appending(path: "My files rclone.conf")

                try await drive.service.exportRcloneConfig(drive.connection, credentials: nil, to: config)

                let remotes = try await dump(drive, config)
                let keys = Set(remotes.values.flatMap(\.keys))
                #expect(keys.isDisjoint(with: ["pass", "key_file_pass", "password"]))
                #expect(!(try String(contentsOf: config, encoding: .utf8)).contains(SFTPFixture.password))
                let environment = login == .agent ? ["SSH_AUTH_SOCK": sftp.agentSocket.path] : [:]
                await #expect(throws: (any Error).self) {
                    _ = try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt", environment: environment)
                }
                if login == .password { _ = try await rclone(drive, config, "config", "update", "unlocalfs-sftp", "pass=\(SFTPFixture.password)", "--obscure") }
                if login == .protectedKey { _ = try await rclone(drive, config, "config", "update", "unlocalfs-sftp", "key_file_pass=\(SFTPFixture.passphrase)", "--obscure") }
                _ = try await rclone(drive, config, "config", "update", "unlocalfs", "password=\(encryptedDriveCredentials.encryptionPassword)", "--obscure")
                #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt", environment: environment) == "top secret")
            }
        }

        @Test func exportedSFTPConfigStillRefusesAChangedServerKey() async throws {
            try await withSFTPDrive(.password, encrypted: true) { drive, sftp in
                try await writeEncrypted("top secret", named: "secret plan.txt", to: sftp.served, executable: drive.executable)
                let config = sftp.root.appending(path: "My files rclone.conf")
                let credentials = try await drive.service.prepareCredentials(sftp.credentials(.password, encryptionPassword: encryptedDriveCredentials.encryptionPassword))
                try await drive.service.exportRcloneConfig(drive.connection, credentials: credentials, to: config)
                #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")

                try await sftp.restartServer(hostKey: "other-host")

                await #expect {
                    _ = try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt")
                } throws: { $0.localizedDescription.contains("knownhosts") }
            }
        }

        @Test(arguments: ["clients/acme", "/clients/acme", #"clients/a"b,c #1;x"#, ""])
        func exportedSFTPConfigKeepsTheRemoteFolder(folder: String) async throws {
            try await withSFTPDrive(.key, folder: folder, encrypted: true) { drive, sftp in
                let storage = sftp.served.appending(path: folder)
                try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
                try await writeEncrypted("top secret", named: "secret plan.txt", to: storage, executable: drive.executable)
                let config = sftp.root.appending(path: "My files rclone.conf")
                let credentials = try await drive.service.prepareCredentials(sftp.credentials(.key, encryptionPassword: encryptedDriveCredentials.encryptionPassword))

                try await drive.service.exportRcloneConfig(drive.connection, credentials: credentials, to: config)

                #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
            }
        }

    }
}

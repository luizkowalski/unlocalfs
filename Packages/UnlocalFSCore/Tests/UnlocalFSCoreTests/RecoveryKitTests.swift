import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

extension MountTests {
    @MainActor @Test func exportedConfigReadsFilesUploadedThroughTheDrive() async throws {
        try await withAppDrive(encrypted: true, credentials: encryptedDriveCredentials) { drive, app, desktop in
            let credentials = try await drive.service.prepareCredentials(
                encryptedDriveCredentials)
            try await drive.service.mount(drive.connection, credentials: credentials)
            try Data("top secret".utf8).write(to: drive.mounted.appendingPathComponent("secret plan.txt"))
            try await drive.waitForUploads(on: drive.service)
            try await drive.service.unmount(drive.connection)
            let config = drive.paths.config.deletingLastPathComponent().appending(path: "My files rclone.conf")

            desktop.rcloneConfigDestination = RcloneConfigDestination(url: config, includesSecrets: true)
            await app.exportRcloneConfig(drive.connection)
            #expect(app.alert == nil)

            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
            let remotes = try await dump(drive, config)
            #expect(remotes["unlocalfs-s3"]?["directory_markers"] == "true")
            #expect(remotes["unlocalfs-s3"]?["no_check_bucket"] == "true")
            #expect(remotes["unlocalfs"]?["filename_encryption"] == "standard")
            #expect(remotes["unlocalfs"]?["directory_name_encryption"] == "true")
            #expect(remotes["unlocalfs"]?["filename_encoding"] == "base32")
        }
    }

    @MainActor @Test(arguments: ["clients/acme", #"clients/a"b,c #1;x"#])
    func exportedConfigReadsFolderDrives(folder: String) async throws {
        try await withAppDrive(folder: folder, encrypted: true, credentials: encryptedDriveCredentials) { drive, app, desktop in
            let storage = drive.bucket.appendingPathComponent(folder)
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            try await writeEncrypted("top secret", named: "secret plan.txt", to: storage, executable: drive.executable)
            let config = drive.paths.config.deletingLastPathComponent().appending(path: "My files rclone.conf")

            desktop.rcloneConfigDestination = RcloneConfigDestination(url: config, includesSecrets: true)
            await app.exportRcloneConfig(drive.connection)
            #expect(app.alert == nil)

            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
        }
    }

    @MainActor @Test func exportedConfigWithoutSecretsWorksWhenCredentialStorageIsUnavailable() async throws {
        try await withAppDrive(
            encrypted: true, credentials: encryptedDriveCredentials,
            credentialStorage: MemoryCredentialStorage(readError: AppError("Keychain unavailable"))
        ) { drive, app, desktop in
            try await writeEncrypted("top secret", named: "secret plan.txt", to: drive.bucket, executable: drive.executable)
            let config = drive.paths.config.deletingLastPathComponent().appending(path: "My files rclone.conf")

            desktop.rcloneConfigDestination = RcloneConfigDestination(url: config, includesSecrets: false)
            await app.exportRcloneConfig(drive.connection)
            #expect(app.alert == nil)

            let remotes = try await dump(drive, config)
            let keys = Set(remotes.values.flatMap(\.keys))
            #expect(keys.isDisjoint(with: ["access_key_id", "secret_access_key", "session_token", "password"]))
            let credentials = encryptedDriveCredentials
            _ = try await rclone(
                drive, config, "config", "update", "unlocalfs-s3",
                "access_key_id=\(credentials.accessKey)", "secret_access_key=\(credentials.secretKey)")
            _ = try await rclone(drive, config, "config", "update", "unlocalfs", "password=\(credentials.encryptionPassword)", "--obscure")
            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
        }
    }

    @MainActor @Test func exportReplacesAnExistingFileAndKeepsItPrivate() async throws {
        try await withAppDrive(encrypted: true, credentials: encryptedDriveCredentials) { drive, app, desktop in
            let config = drive.paths.config.deletingLastPathComponent().appending(path: "My files rclone.conf")
            try Data("[other]\ntype = alias\nremote = /tmp\n".utf8).write(to: config)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: config.path)

            desktop.rcloneConfigDestination = RcloneConfigDestination(url: config, includesSecrets: true)
            await app.exportRcloneConfig(drive.connection)
            #expect(app.alert == nil)

            #expect(try await Set(dump(drive, config).keys) == ["unlocalfs", "unlocalfs-s3"])
            let permissions = try FileManager.default.attributesOfItem(atPath: config.path)[.posixPermissions] as? Int
            #expect(permissions == 0o600)
        }
    }

    @Test func foldersCreatedOnTheDriveAreStoredInTheBucket() async throws {
        try await withDrive { drive in
            try await drive.service.mount(drive.connection, credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            try FileManager.default.createDirectory(at: drive.mounted.appendingPathComponent("empty folder"), withIntermediateDirectories: false)
            try await drive.waitForUploads(on: drive.service)
            try await drive.service.unmount(drive.connection)
            #expect(FileManager.default.fileExists(atPath: drive.bucket.appendingPathComponent("empty folder").path))
        }
    }
}

extension MountTests {
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

            let environment = ["SSH_AUTH_SOCK": sftp.agent.socket.path]
            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt", environment: environment) == "top secret")
            let remote = try #require(try await dump(drive, config)["unlocalfs-sftp"])
            #expect(remote["shell_type"] == "none" && remote["known_hosts_file"] == sftp.knownHosts.path)
            #expect(remote["port"] == "\(SFTPFixture.port)" && remote["user"] == "test" && remote["host"] == "127.0.0.1")
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
            let environment = ["SSH_AUTH_SOCK": sftp.agent.socket.path]
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

private let encryptedDriveCredentials = Credentials(accessKey: "test-key", secretKey: "test-secret", encryptionPassword: "-correct horse ")

private func rclone(_ drive: Drive, _ config: URL, _ arguments: String..., environment: [String: String] = [:]) async throws -> String {
    let output = try await Command.run(
        drive.executable, arguments + ["--config", config.path],
        environment: ["HOME": URL.homeDirectory.path, "PATH": "/usr/bin:/bin"].merging(environment) { _, new in new })
    return String(decoding: output, as: UTF8.self)
}

private func dump(_ drive: Drive, _ config: URL) async throws -> [String: [String: String]] {
    try await JSONDecoder().decode([String: [String: String]].self, from: Data(rclone(drive, config, "config", "dump").utf8))
}

private func writeEncrypted(_ contents: String, named name: String, to storage: URL, executable: URL) async throws {
    let password = try await Command.run(executable, ["obscure", "-", "--config", "/dev/null"], input: encryptedDriveCredentials.encryptionPassword)
    _ = try await Command.run(
        executable, ["rcat", ":crypt:\(name)", "--config", "/dev/null"], input: contents,
        environment: [
            "RCLONE_CRYPT_REMOTE": storage.path,
            "RCLONE_CRYPT_PASSWORD": String(decoding: password, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        ])
}

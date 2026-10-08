import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

extension IntegrationTests.DriveFeatureTests {
    @MainActor @Test func exportedConfigReadsFilesUploadedThroughTheDrive() async throws {
        try await withAppDrive(encrypted: true, credentials: encryptedDriveCredentials) { drive, app, desktop in
            let credentials = try await drive.service.prepareCredentials(
                encryptedDriveCredentials)
            try await drive.service.mount(drive.connection, credentials: credentials)
            try Data("top secret".utf8).write(to: drive.mounted.appendingPathComponent("secret plan.txt"))
            try await drive.waitForUploads(on: drive.service)
            try await drive.service.unmount(drive.connection)
            let config = drive.paths.config.deletingLastPathComponent().appending(path: "My files rclone.conf")
            try Data("[other]\ntype = alias\nremote = /tmp\n".utf8).write(to: config)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: config.path)

            desktop.rcloneConfigDestination = RcloneConfigDestination(url: config, includesSecrets: true)
            await app.exportRcloneConfig(drive.connection)
            #expect(app.alert == nil)

            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
            let remotes = try await dump(drive, config)
            #expect(Set(remotes.keys) == ["unlocalfs", "unlocalfs-s3"], "replaces an existing file")
            let permissions = try FileManager.default.attributesOfItem(atPath: config.path)[.posixPermissions] as? Int
            #expect(permissions == 0o600)
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
            try await drive.service.test(drive.connection, credentials: encryptedDriveCredentials)
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
}

let encryptedDriveCredentials = Credentials(accessKey: "test-key", secretKey: "test-secret", encryptionPassword: "-correct horse ")

func rclone(_ drive: Drive, _ config: URL, _ arguments: String..., environment: [String: String] = [:]) async throws -> String {
    let output = try await Command.run(
        drive.executable, arguments + ["--config", config.path],
        environment: ["HOME": URL.homeDirectory.path, "PATH": "/usr/bin:/bin"].merging(environment) { _, new in new })
    return String(decoding: output, as: UTF8.self)
}

func dump(_ drive: Drive, _ config: URL) async throws -> [String: [String: String]] {
    try await JSONDecoder().decode([String: [String: String]].self, from: Data(rclone(drive, config, "config", "dump").utf8))
}

func writeEncrypted(_ contents: String, named name: String, to storage: URL, executable: URL) async throws {
    let password = try await Command.run(executable, ["obscure", "-", "--config", "/dev/null"], input: encryptedDriveCredentials.encryptionPassword)
    _ = try await Command.run(
        executable, ["rcat", ":crypt:\(name)", "--config", "/dev/null"], input: contents,
        environment: [
            "RCLONE_CRYPT_REMOTE": storage.path,
            "RCLONE_CRYPT_PASSWORD": String(decoding: password, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        ])
}

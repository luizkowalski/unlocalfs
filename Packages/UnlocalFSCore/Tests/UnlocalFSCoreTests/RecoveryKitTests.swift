import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

extension MountTests {
    @Test func exportedConfigReadsFilesUploadedThroughTheDrive() async throws {
        try await withDrive(encrypted: true) { drive in
            let credentials = try await drive.service.prepareCredentials(
                Credentials(accessKey: "test-key", secretKey: "test-secret", encryptionPassword: "correct horse"))
            try await drive.service.mount(drive.connection, credentials: credentials)
            try Data("top secret".utf8).write(to: drive.mounted.appendingPathComponent("secret plan.txt"))
            try await drive.waitForUploads(on: drive.service)
            try await drive.service.unmount(drive.connection)
            let config = try exportLocation()

            try await drive.service.exportRcloneConfig(drive.connection, credentials: credentials, to: config)

            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
            let remotes = try await dump(drive, config)
            #expect(remotes["unlocalfs-s3"]?["directory_markers"] == "true")
            #expect(remotes["unlocalfs"]?["filename_encryption"] == "standard")
            #expect(remotes["unlocalfs"]?["directory_name_encryption"] == "true")
            #expect(remotes["unlocalfs"]?["filename_encoding"] == "base32")
        }
    }

    @Test(arguments: ["clients/acme", #"clients/a"b,c #1;x"#])
    func exportedConfigReadsFolderDrives(folder: String) async throws {
        try await withDrive(folder: folder, encrypted: true) { drive in
            let storage = drive.bucket.appendingPathComponent(folder)
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            try await writeEncrypted("top secret", named: "secret plan.txt", to: storage, executable: drive.executable)
            let config = try exportLocation()

            try await drive.service.exportRcloneConfig(
                drive.connection, credentials: Credentials(accessKey: "test-key", secretKey: "test-secret", encryptionPassword: "correct horse"),
                to: config)

            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
        }
    }

    @Test func exportedConfigWithoutSecretsReadsTheDriveAfterAddingThem() async throws {
        try await withDrive(encrypted: true) { drive in
            try await writeEncrypted("top secret", named: "secret plan.txt", to: drive.bucket, executable: drive.executable)
            let config = try exportLocation()

            try await drive.service.exportRcloneConfig(drive.connection, credentials: nil, to: config)

            let remotes = try await dump(drive, config)
            let keys = Set(remotes.values.flatMap(\.keys))
            #expect(keys.isDisjoint(with: ["access_key_id", "secret_access_key", "session_token", "password"]))
            let key = "test-key", secret = "test-secret", password = "correct horse"
            _ = try await rclone(drive, config, "config", "update", "unlocalfs-s3", "access_key_id", key, "secret_access_key", secret)
            _ = try await rclone(drive, config, "config", "update", "unlocalfs", "password", password, "--obscure")
            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
        }
    }

    @Test func exportReplacesAnExistingFileAndKeepsItPrivate() async throws {
        try await withDrive(encrypted: true) { drive in
            let config = try exportLocation()
            try Data("[other]\ntype = alias\nremote = /tmp\n".utf8).write(to: config)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: config.path)

            try await drive.service.exportRcloneConfig(
                drive.connection, credentials: Credentials(accessKey: "test-key", secretKey: "test-secret", encryptionPassword: "correct horse"),
                to: config)

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

private func exportLocation() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("uf-export-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("My files rclone.conf")
}

private func rclone(_ drive: Drive, _ config: URL, _ arguments: String...) async throws -> String {
    let output = try await Command.run(
        drive.executable, arguments + ["--config", config.path],
        environment: ["HOME": URL.homeDirectory.path, "PATH": "/usr/bin:/bin"])
    return String(decoding: output, as: UTF8.self)
}

private func dump(_ drive: Drive, _ config: URL) async throws -> [String: [String: String]] {
    try await JSONDecoder().decode([String: [String: String]].self, from: Data(rclone(drive, config, "config", "dump").utf8))
}

private func writeEncrypted(_ contents: String, named name: String, to storage: URL, executable: URL) async throws {
    let password = try await Command.run(executable, ["obscure", "-", "--config", "/dev/null"], input: "correct horse")
    _ = try await Command.run(
        executable, ["rcat", ":crypt:\(name)", "--config", "/dev/null"], input: contents,
        environment: [
            "RCLONE_CRYPT_REMOTE": storage.path,
            "RCLONE_CRYPT_PASSWORD": String(decoding: password, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        ])
}

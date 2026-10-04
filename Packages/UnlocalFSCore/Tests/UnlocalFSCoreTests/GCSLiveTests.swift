import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

private let environment = ProcessInfo.processInfo.environment
private let liveBucket = environment["UNLOCALFS_GCS_BUCKET"]
private let liveKeyFile = environment["UNLOCALFS_GCS_KEY_FILE"]
private let setup = """
Set UNLOCALFS_GCS_BUCKET to a scratch bucket with uniform access and UNLOCALFS_GCS_KEY_FILE to the key of a service account \
whose only role on it is Storage Object User
"""

extension MountTests {
    @Test(.enabled(if: liveBucket != nil && liveKeyFile != nil, Comment(rawValue: setup)))
    func gcsDriveReadsAndWritesABucketWithObjectOnlyAccess() async throws {
        try await withLiveDrive(encrypted: false) { drive, credentials, config, remote in
            try await drive.service.test(drive.connection, credentials: credentials)
            try await drive.service.mount(drive.connection, credentials: credentials)
            try Data("plan".utf8).write(to: drive.mounted.appending(path: "plan.txt"))
            try Data("old".utf8).write(to: drive.mounted.appending(path: "old.txt"))
            try FileManager.default.createDirectory(at: drive.mounted.appending(path: "empty"), withIntermediateDirectories: false)
            try await drive.waitForUploads(on: drive.service)
            try FileManager.default.moveItem(at: drive.mounted.appending(path: "plan.txt"), to: drive.mounted.appending(path: "renamed.txt"))
            try FileManager.default.removeItem(at: drive.mounted.appending(path: "old.txt"))
            try await drive.waitForUploads(on: drive.service)
            try await drive.service.unmount(drive.connection)

            #expect(Set(try await rclone(drive, config, "lsf", remote).split(separator: "\n")) == ["renamed.txt", "empty/"])
            #expect(try await rclone(drive, config, "cat", "\(remote)/renamed.txt") == "plan")
        }
    }

    @Test(.enabled(if: liveBucket != nil && liveKeyFile != nil, Comment(rawValue: setup)))
    func exportedConfigReadsAnEncryptedGCSDrive() async throws {
        try await withLiveDrive(encrypted: true) { drive, credentials, config, _ in
            try await drive.service.mount(drive.connection, credentials: credentials)
            try Data("top secret".utf8).write(to: drive.mounted.appending(path: "secret plan.txt"))
            try await drive.waitForUploads(on: drive.service)
            try await drive.service.unmount(drive.connection)

            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
        }
    }
}

private func withLiveDrive(
    encrypted: Bool, _ body: (Drive, Credentials, URL, String) async throws -> Void
) async throws {
    var connection = gcsFixture()
    connection.bucket = try #require(liveBucket)
    connection.folder = "unlocalfs-live-\(UUID().uuidString.prefix(8))"
    connection.encrypted = encrypted
    let key = try ServiceAccountKey(importing: Data(contentsOf: URL(fileURLWithPath: try #require(liveKeyFile))))
    let secrets = Credentials(encryptionPassword: encrypted ? "-correct horse " : "", serviceAccountKey: key.json)
    try await withDrive(encrypted: encrypted, connection: connection) { drive in
        let config = drive.paths.config.deletingLastPathComponent().appending(path: "live.conf")
        let remote = "unlocalfs-gcs:\(connection.bucket)/\(connection.folder)"
        try await drive.service.exportRcloneConfig(drive.connection, credentials: secrets, to: config)
        let credentials = try await drive.service.prepareCredentials(secrets)
        do {
            try await body(drive, credentials, config, remote)
        } catch {
            _ = try? await rclone(drive, config, "purge", remote)
            throw error
        }
        _ = try? await rclone(drive, config, "purge", remote)
    }
}

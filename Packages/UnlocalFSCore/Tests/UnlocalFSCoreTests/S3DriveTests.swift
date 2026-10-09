import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite(.timeLimit(.minutes(2))) struct S3DriveTests {
    @Test func driveDownloadsUploadsAndDeletesFiles() async throws {
        try await withS3Drive { drive, bucket in
            try await verifyRoundTrip(drive, storage: bucket, credentials: s3Credentials)
        }
    }

    @Test func encryptedDriveStoresOnlyCiphertextThatItsExportedConfigCanRead() async throws {
        try await withS3Drive(encrypted: true) { drive, bucket in
            let credentials = try await drive.service.prepareCredentials(
                Credentials(accessKey: "test-key", secretKey: "test-secret", encryptionPassword: "-correct horse ")
            )
            try await drive.service.mount(drive.connection, credentials: credentials)
            try Data("top secret".utf8).write(to: drive.mounted.appending(path: "secret plan.txt"))
            try await drive.waitForUploads()
            try await drive.service.unmount(drive.connection)

            let stored = try FileManager.default.contentsOfDirectory(atPath: bucket.path)
            let object = try #require(stored.first)
            #expect(stored.count == 1)
            #expect(!object.contains("secret"))
            #expect(try !String(decoding: Data(contentsOf: bucket.appending(path: object)), as: UTF8.self).contains("top secret"))

            let config = drive.paths.support.appending(path: "My files rclone.conf")
            try await drive.service.exportRcloneConfig(drive.connection, credentials: credentials, to: config)
            #expect(try await rclone(drive, config, "cat", "unlocalfs:secret plan.txt") == "top secret")
        }
    }
}

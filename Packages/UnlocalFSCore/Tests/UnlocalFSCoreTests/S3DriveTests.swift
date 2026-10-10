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

    @Test func openFileKeepsTheDriveConnectedUntilItCloses() async throws {
        try await withS3Drive { drive, bucket in
            try Data("open file".utf8).write(to: bucket.appending(path: "open.txt"))
            try await drive.service.mount(drive.connection, credentials: s3Credentials)
            let file = try FileHandle(forReadingFrom: drive.mounted.appending(path: "open.txt"))
            defer { try? file.close() }

            await #expect(throws: DriveEjectError.self) { try await drive.service.unmount(drive.connection) }
            #expect(await drive.service.status(drive.connection).isMounted)

            try file.close()
            try await drive.service.unmount(drive.connection)
            #expect(await !drive.service.status(drive.connection).isActive)
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

    @Test func onlyAmazonS3DrivesExportStorageClassAndEncryption() async throws {
        let key = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
        var amazon = fixture()
        amazon.provider = .aws
        let defaults = amazon
        amazon.aws.storageClass = .standardInfrequentAccess
        amazon.aws.serverSideEncryption = .kms
        amazon.aws.kmsKeyID = key
        var leftoverKey = amazon
        leftoverKey.aws.serverSideEncryption = .s3Managed
        var minio = amazon
        minio.provider = .minio
        try await withOfflineDrive(fixture()) { drive in
            func exported(_ connection: Connection) async throws -> [String: String] {
                let config = drive.paths.config.deletingLastPathComponent().appending(path: "\(UUID()).conf")
                try await drive.service.exportRcloneConfig(connection, credentials: nil, to: config)
                let options = try await dump(drive, config)["unlocalfs-s3"] ?? [:]
                return options.filter { ["storage_class", "server_side_encryption", "sse_kms_key_id"].contains($0.key) }
            }
            var exports: [[String: String]] = []
            for connection in [amazon, leftoverKey, minio, defaults] { exports.append(try await exported(connection)) }
            #expect(exports == [
                ["storage_class": "STANDARD_IA", "server_side_encryption": "aws:kms", "sse_kms_key_id": key],
                ["storage_class": "STANDARD_IA", "server_side_encryption": "AES256"],
                [:],
                [:]
            ])
        }
    }
}

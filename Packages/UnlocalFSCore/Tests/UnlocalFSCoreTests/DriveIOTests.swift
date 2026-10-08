import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite(.timeLimit(.minutes(2)))
struct DriveIOTests {
    @Test func driveUsesOneMegabyteRequestsAndShortReadAhead() async throws {
        try await withDrive { drive in
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            let output = try await Command.run(URL(filePath: "/usr/bin/nfsstat"), ["-m", drive.mounted.path])
            let current = try #require(String(decoding: output, as: UTF8.self).components(separatedBy: "Current mount parameters").last)
            #expect(current.contains("rsize=1048576,wsize=1048576,readahead=4"))
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test func peekingIntoALargeFileDownloadsLessThanSixteenMegabytes() async throws {
        try await withDrive { drive in
            let size: UInt64 = 32 << 20
            let stored = drive.bucket.appendingPathComponent("movie.mkv")
            FileManager.default.createFile(atPath: stored.path, contents: nil)
            let writer = try FileHandle(forWritingTo: stored)
            try writer.truncate(atOffset: size)
            try writer.close()
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            let reader = try FileHandle(forReadingFrom: drive.mounted.appendingPathComponent("movie.mkv"))
            _ = try reader.read(upToCount: 1 << 20)
            try reader.seek(toOffset: size - (1 << 20))
            _ = try reader.read(upToCount: 1 << 20)
            try reader.close()
            #expect(try await waitUntil(timeout: .seconds(20)) { try await drive.control("core/stats")["transferring"] == nil })
            let downloaded = try #require(try await drive.control("core/stats")["bytes"] as? Int64)
            #expect(downloaded < 16 << 20)
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test func objectStorageDriveReadsInFourParallelStreams() async throws {
        try await withDrive { drive in
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            let vfs = try #require(try await drive.control("options/get")["vfs"] as? [String: Any])
            #expect(vfs["ChunkStreams"] as? Int64 == 4)
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test func sftpDriveReadsInOneStream() async throws {
        try await withSFTPDrive { drive, sftp in
            try await drive.service.mount(drive.connection, credentials: sftp.credentials(.password))
            let vfs = try #require(try await drive.control("options/get")["vfs"] as? [String: Any])
            #expect(vfs["ChunkStreams"] as? Int64 == 0)
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test func disconnectWaitsForAppsToCloseTheirFiles() async throws {
        try await withDrive { drive in
            try Data("hello from S3".utf8).write(to: drive.bucket.appendingPathComponent("hello.txt"))
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            let reader = try FileHandle(forReadingFrom: drive.mounted.appendingPathComponent("hello.txt"))
            let closing = Task {
                try await Task.sleep(for: .seconds(2))
                try reader.close()
            }
            try await drive.service.unmount(drive.connection)
            try await closing.value
            #expect(await !drive.service.status(drive.connection).isActive)
        }
    }
}

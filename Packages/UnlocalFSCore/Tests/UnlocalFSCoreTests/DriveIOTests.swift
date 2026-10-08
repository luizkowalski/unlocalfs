import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

extension IntegrationTests {
    @Suite
    struct DriveIOTests {
        @Test func s3DriveMountsTidilyAndPeeksIntoLargeFilesWithoutDownloadingThem() async throws {
            try await withDrive { drive in
                let size: UInt64 = 32 << 20
                let movie = drive.bucket.appendingPathComponent("movie.mkv")
                FileManager.default.createFile(atPath: movie.path, contents: nil)
                let writer = try FileHandle(forWritingTo: movie)
                try writer.truncate(atOffset: size)
                try writer.close()
                try FileManager.default.createDirectory(at: drive.bucket.appendingPathComponent("docs"), withIntermediateDirectories: true)
                try FileManager.default.createDirectory(
                    at: drive.paths.mounts.appending(path: drive.connection.name.lowercased()), withIntermediateDirectories: true)
                try drive.paths.prepare()
                let log = drive.paths.log(drive.connection)
                try Data(repeating: 120, count: 6 << 20).write(to: log)

                try await drive.service.mount(drive.connection, credentials: s3Credentials)

                #expect(await drive.service.status(drive.connection).isMounted, "reuses a mount folder named in a different case")
                let docs = try FileManager.default.attributesOfItem(atPath: drive.mounted.appendingPathComponent("docs").path)
                #expect(abs(try #require(docs[.modificationDate] as? Date).timeIntervalSinceNow) < 60, "stamps folders with the connect time")
                let output = try await Command.run(URL(filePath: "/usr/bin/nfsstat"), ["-m", drive.mounted.path])
                let current = try #require(String(decoding: output, as: UTF8.self).components(separatedBy: "Current mount parameters").last)
                #expect(current.contains("rsize=1048576,wsize=1048576,readahead=4"))
                let vfs = try #require(try await drive.control("options/get")["vfs"] as? [String: Any])
                #expect(vfs["ChunkStreams"] as? Int64 == 4)
                #expect(vfs["CacheMinFreeSpace"] as? Int64 == -1)
                let reader = try FileHandle(forReadingFrom: drive.mounted.appendingPathComponent("movie.mkv"))
                _ = try reader.read(upToCount: 1 << 20)
                try reader.seek(toOffset: size - (1 << 20))
                _ = try reader.read(upToCount: 1 << 20)
                try reader.close()
                try await waitUntil(timeout: .seconds(20)) { try await drive.control("core/stats")["transferring"] == nil }
                let downloaded = try #require(try await drive.control("core/stats")["bytes"] as? Int64)
                #expect(downloaded < 16 << 20, "peeking downloads less than sixteen megabytes")

                try await drive.service.unmount(drive.connection)

                #expect(try FileManager.default.contentsOfDirectory(atPath: drive.paths.logs.path).count == 2, "rotates the oversized log")
                #expect(try #require(log.resourceValues(forKeys: [.fileSizeKey]).fileSize) < 1024 * 1024)
            }
        }

        @Test func refreshShowsNewFilesAndDisconnectWaitsForAppsToCloseTheirFiles() async throws {
            try await withDrive { drive in
                let docs = drive.bucket.appendingPathComponent("docs")
                try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
                try Data("old".utf8).write(to: docs.appendingPathComponent("old.txt"))
                try await drive.service.mount(drive.connection, credentials: s3Credentials)
                let mountedDocs = drive.mounted.appendingPathComponent("docs")
                #expect(try FileManager.default.contentsOfDirectory(atPath: mountedDocs.path) == ["old.txt"])
                try Data("new".utf8).write(to: docs.appendingPathComponent("new.txt"))
                #expect(try FileManager.default.contentsOfDirectory(atPath: mountedDocs.path) == ["old.txt"])
                try await drive.service.refresh(drive.connection)
                try await waitUntil { try FileManager.default.contentsOfDirectory(atPath: mountedDocs.path).contains("new.txt") }
                #expect(try FileManager.default.contentsOfDirectory(atPath: mountedDocs.path).sorted() == ["new.txt", "old.txt"])

                let reader = try FileHandle(forReadingFrom: mountedDocs.appendingPathComponent("old.txt"))
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
}

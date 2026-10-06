import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

extension MountTests {
    @Test func refreshShowsFilesAddedToTheBucketElsewhere() async throws {
        try await withDrive { drive in
            let docs = drive.bucket.appendingPathComponent("docs")
            try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
            try Data("old".utf8).write(to: docs.appendingPathComponent("old.txt"))
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            let mountedDocs = drive.mounted.appendingPathComponent("docs")
            #expect(try FileManager.default.contentsOfDirectory(atPath: mountedDocs.path) == ["old.txt"])
            try Data("new".utf8).write(to: docs.appendingPathComponent("new.txt"))
            #expect(try FileManager.default.contentsOfDirectory(atPath: mountedDocs.path) == ["old.txt"])
            try await drive.service.refresh(drive.connection)
            try await waitUntil { try FileManager.default.contentsOfDirectory(atPath: mountedDocs.path).contains("new.txt") }
            #expect(try FileManager.default.contentsOfDirectory(atPath: mountedDocs.path).sorted() == ["new.txt", "old.txt"])
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test func foldersShowWhenTheDriveConnected() async throws {
        try await withDrive { drive in
            try FileManager.default.createDirectory(at: drive.bucket.appendingPathComponent("docs"), withIntermediateDirectories: true)
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            let attributes = try FileManager.default.attributesOfItem(atPath: drive.mounted.appendingPathComponent("docs").path)
            let modified = try #require(attributes[.modificationDate] as? Date)
            #expect(abs(modified.timeIntervalSinceNow) < 60)
            try await drive.service.unmount(drive.connection)
        }
    }
}

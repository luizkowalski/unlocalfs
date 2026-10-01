import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

extension MountTests {
    @Test func shareLinksRefuseFilesStillUploading() async throws {
        try await withPendingUpload { drive, credentials in
            await #expect {
                _ = try await drive.service.shareLink(for: drive.connection, path: "report.txt", expiry: .day, credentials: credentials)
            } throws: { error in
                error is AppError && error.localizedDescription.contains("still uploading")
            }
        }
    }

    @Test func shareLinksIgnoreOtherFilesStillUploading() async throws {
        try await withPendingUpload { drive, credentials in
            let link = try await drive.service.shareLink(for: drive.connection, path: "ready.txt", expiry: .day, credentials: credentials)
            let (data, response) = try await URLSession.shared.data(from: link)
            #expect((response as? HTTPURLResponse)?.statusCode == 200)
            #expect(String(decoding: data, as: UTF8.self) == "ready content")
        }
    }

    @Test(arguments: ["", "clients/acme"])
    func sharedLinkDownloadsTheFile(folder: String) async throws {
        try await withDrive(folder: folder) { drive in
            let storage = drive.bucket.appending(path: folder)
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            try Data("shared plan".utf8).write(to: storage.appending(path: "trip plan.txt"))
            let link = try await drive.service.shareLink(
                for: drive.connection, path: "trip plan.txt", expiry: .day,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            let (data, response) = try await URLSession.shared.data(from: link)
            #expect((response as? HTTPURLResponse)?.statusCode == 200)
            #expect(String(decoding: data, as: UTF8.self) == "shared plan")
            let expires = URLComponents(url: link, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "X-Amz-Expires" }
            #expect(expires?.value == "86400")
        }
    }
}

private func withPendingUpload(_ body: (Drive, Credentials) async throws -> Void) async throws {
    try await withDrive { drive in
        try Data("old content".utf8).write(to: drive.bucket.appending(path: "report.txt"))
        try Data("ready content".utf8).write(to: drive.bucket.appending(path: "ready.txt"))
        let credentials = Credentials(accessKey: "test-key", secretKey: "test-secret")
        try await drive.service.mount(drive.connection, credentials: credentials)
        let report = drive.mounted.appending(path: "report.txt")
        _ = try Data(contentsOf: report)
        try Data("new content".utf8).write(to: report)
        try #require(try await drive.service.activity(drive.connection).contains { $0.path == "report.txt" && $0.state != .downloading })
        try await body(drive, credentials)
        try await drive.waitForUploads(on: drive.service)
        try await drive.service.unmount(drive.connection)
    }
}

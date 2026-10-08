import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure

extension IntegrationTests.DriveFeatureTests {
    @Test func shareLinksRefuseFilesStillUploadingButNotOtherFiles() async throws {
        try await withDrive { drive in
            try Data("old content".utf8).write(to: drive.bucket.appending(path: "report.txt"))
            try Data("ready content".utf8).write(to: drive.bucket.appending(path: "ready.txt"))
            try await drive.service.mount(drive.connection, credentials: s3Credentials)
            let report = drive.mounted.appending(path: "report.txt")
            _ = try Data(contentsOf: report)
            try Data("new content".utf8).write(to: report)
            try #require(try await drive.service.activity(drive.connection).contains { $0.path == "report.txt" && $0.state != .downloading })

            await #expect {
                _ = try await drive.service.shareLink(for: drive.connection, path: "report.txt", expiry: .day, credentials: s3Credentials)
            } throws: { error in
                error is AppError && error.localizedDescription == String(localized: .fileStillUploading)
            }
            _ = try await drive.service.shareLink(for: drive.connection, path: "ready.txt", expiry: .day, credentials: s3Credentials)

            try await drive.waitForUploads(on: drive.service)
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test(arguments: ["", "clients/acme"])
    func sharedLinkDownloadsTheFile(folder: String) async throws {
        try await withDrive(folder: folder) { drive in
            let storage = drive.bucket.appending(path: folder)
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            try Data("shared plan".utf8).write(to: storage.appending(path: "trip plan.txt"))
            try await drive.service.mount(drive.connection, credentials: s3Credentials)
            let link = try await drive.service.shareLink(
                for: drive.connection, path: "trip plan.txt", expiry: .day,
                credentials: s3Credentials)
            let (data, response) = try await URLSession.shared.data(from: link)
            #expect((response as? HTTPURLResponse)?.statusCode == 200)
            #expect(String(decoding: data, as: UTF8.self) == "shared plan")
            let expires = URLComponents(url: link, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "X-Amz-Expires" }
            #expect(expires?.value == "86400")
            try await drive.service.unmount(drive.connection)
        }
    }
}

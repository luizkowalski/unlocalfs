import Foundation
import Testing
import UnlocalFSCore

extension MountTests {
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

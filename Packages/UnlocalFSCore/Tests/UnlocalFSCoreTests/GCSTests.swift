import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

private let storedKey = (try? ServiceAccountKey(importing: Data(serviceAccountJSON.utf8)))?.json ?? ""

@Suite struct GCSTests {
    @Test func gcsDriveAcceptsAnInlineKeyAndExportsItOnOneLineOnlyWhenSecretsAreIncluded() async throws {
        var connection = gcsFixture()
        connection.encrypted = true
        connection.folder = "clients/acme"
        try await withRclone(connection: connection) { drive in
            let credentials = Credentials(encryptionPassword: "-correct horse ", serviceAccountKey: storedKey)
            await #expect {
                try await drive.service.test(drive.connection, credentials: credentials)
            } throws: { error in
                error.localizedDescription.contains("private key")
            }
            let withSecrets = drive.paths.config.deletingLastPathComponent().appending(path: "with.conf")
            let withoutSecrets = drive.paths.config.deletingLastPathComponent().appending(path: "without.conf")
            try await drive.service.exportRcloneConfig(drive.connection, credentials: credentials, to: withSecrets)
            try await drive.service.exportRcloneConfig(drive.connection, credentials: nil, to: withoutSecrets)

            await #expect {
                _ = try await rclone(drive, withSecrets, "lsf", "unlocalfs-gcs:my-bucket")
            } throws: { error in
                error.localizedDescription.contains("private key")
            }
            let remotes = try await dump(drive, withSecrets)
            #expect(remotes["unlocalfs-gcs"]?["service_account_credentials"] == storedKey)
            #expect(remotes["unlocalfs"]?["remote"] == "unlocalfs-gcs:my-bucket/clients/acme")
            #expect(try String(contentsOf: withSecrets, encoding: .utf8).split(separator: "\n").filter { $0.contains("PRIVATE KEY") }.count == 1)
            let bare = try await dump(drive, withoutSecrets)
            #expect(bare["unlocalfs-gcs"]?["service_account_credentials"] == nil)
            #expect(try !String(contentsOf: withoutSecrets, encoding: .utf8).contains("PRIVATE KEY"))
        }
    }
}

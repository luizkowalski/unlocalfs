import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite struct GCSDriveTests {
    @Test func keyReachesRcloneAndExportsOnOneLineOnlyWithSecrets() async throws {
        let storedKey = try ServiceAccountKey(importing: Data(serviceAccountJSON.utf8)).json
        var connection = gcsFixture()
        connection.encrypted = true
        connection.folder = #"clients/a"b,c #1;x"#
        try await withOfflineDrive(connection) { drive in
            let credentials = Credentials(encryptionPassword: "-correct horse ", serviceAccountKey: storedKey)
            let tested = await #expect(throws: (any Error).self) { try await drive.service.test(drive.connection, credentials: credentials) }
            #expect(tested?.localizedDescription.contains("private key") == true)
            let withSecrets = drive.paths.config.deletingLastPathComponent().appending(path: "with.conf")
            let withoutSecrets = drive.paths.config.deletingLastPathComponent().appending(path: "without.conf")
            try await drive.service.exportRcloneConfig(drive.connection, credentials: credentials, to: withSecrets)
            try await drive.service.exportRcloneConfig(drive.connection, credentials: nil, to: withoutSecrets)

            let listed = await #expect(throws: (any Error).self) { try await rclone(drive, withSecrets, "lsf", "unlocalfs-gcs:my-bucket") }
            #expect(listed?.localizedDescription.contains("private key") == true)
            let remotes = try await dump(drive, withSecrets)
            #expect(remotes["unlocalfs-gcs"]?["service_account_credentials"] == storedKey)
            #expect(remotes["unlocalfs"]?["remote"] == #"unlocalfs-gcs:my-bucket/clients/a"b,c #1;x"#)
            #expect(try String(contentsOf: withSecrets, encoding: .utf8).split(separator: "\n").count { $0.contains("PRIVATE KEY") } == 1)
            let bare = try await dump(drive, withoutSecrets)
            #expect(bare["unlocalfs-gcs"]?["service_account_credentials"] == nil)
            #expect(try !String(contentsOf: withoutSecrets, encoding: .utf8).contains("PRIVATE KEY"))
        }
    }
}

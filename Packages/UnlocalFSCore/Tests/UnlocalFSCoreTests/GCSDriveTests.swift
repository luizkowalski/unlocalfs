import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSTestSupport

struct GCSDriveTests {
    @Test func keyReachesRcloneAndExportsOnOneLineOnlyWithSecrets() async throws {
        let storedKey = try ServiceAccountKey(importing: Data(serviceAccountJSON.utf8)).json
        let connection = Connection.gcs {
            $0.encrypted = true
            $0.folder = #"clients/a"b,c #1;x"#
        }
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

    @Test func googleConnectionTestGivesRcloneOnlyTheTokenAndTheClient() async throws {
        let drives = try StubbedDrives("gcs-google") { root in
            """
            if [ "$1" = 'lsf' ]; then
                printf '%s\\n' "$*" > '\(root.path)/lsf-arguments'
                env | grep '^RCLONE_' | sort > '\(root.path)/lsf-environment'
                if [ -f '\(root.path)/lsf-fails' ]; then
                    printf 'failed with %s' "$RCLONE_GCS_TOKEN" >&2
                    exit 1
                fi
            fi
            """
        }
        defer { drives.remove() }
        let connection = Connection.gcs { $0.gcs.authentication = .googleAccount }
        let credentials = Credentials(serviceAccountKey: serviceAccountJSON, googleToken: googleTokenJSON)

        try await drives.service.test(connection, credentials: credentials)

        let environment = try String(contentsOf: drives.root.appending(path: "lsf-environment"), encoding: .utf8)
        #expect(environment.contains("RCLONE_GCS_TOKEN=\(googleTokenJSON)\n"))
        #expect(environment.contains("RCLONE_GCS_CLIENT_ID=\(GoogleClient.test.id)\n"))
        #expect(environment.contains("RCLONE_GCS_CLIENT_SECRET=\(GoogleClient.test.secret)\n"))
        #expect(environment.contains("RCLONE_GCS_ENV_AUTH=false\n"))
        #expect(!environment.contains("SERVICE_ACCOUNT"))
        #expect(try !String(contentsOf: drives.root.appending(path: "lsf-arguments"), encoding: .utf8).contains("refresh"))

        FileManager.default.createFile(atPath: drives.root.appending(path: "lsf-fails").path, contents: Data())
        let failure = await #expect(throws: (any Error).self) { try await drives.service.test(connection, credentials: credentials) }
        #expect(failure?.localizedDescription.contains("failed with") == true)
        #expect(failure?.localizedDescription.contains("refresh") == false)
        #expect(failure?.localizedDescription.contains("ya29") == false)
    }

    @Test(arguments: ["", "not json", #"{"access_token":"ya29.only-access"}"#])
    func googleDriveWithoutASavedRefreshTokenNeverStartsRclone(token: String) async throws {
        let drives = try StubbedDrives("gcs-google")
        defer { drives.remove() }
        let connection = Connection.gcs { $0.gcs.authentication = .googleAccount }

        await #expect(throws: GoogleSignInRequired.self) { try await drives.service.test(connection, credentials: Credentials.google(token)) }
        await #expect(throws: GoogleSignInRequired.self) { try await drives.service.mount(connection, credentials: Credentials.google(token)) }

        #expect(drives.rcloneCalls.isEmpty)
    }
}

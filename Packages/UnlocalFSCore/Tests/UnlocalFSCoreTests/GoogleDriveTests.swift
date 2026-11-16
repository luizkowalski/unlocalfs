import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
import UnlocalFSTestSupport

struct GoogleDriveTests {
    init() { GoogleAPIStub.install() }

    @Test func signInAsksOnlyForFilesUnlocalFSMadeAndReturnsTheAccount() async throws {
        let drives = try signInDrives(token: newTokenJSON)
        defer { drives.remove() }

        let signIn = try await drives.service.signInWithGoogle(for: .googleDrive)

        #expect(signIn == GoogleSignIn(token: newTokenJSON, accountID: "account-1"))
        let environment = try String(contentsOf: drives.root.appending(path: "authorize-env"), encoding: .utf8)
        #expect(environment.contains("RCLONE_DRIVE_CLIENT_ID=\(GoogleClient.test.id)\n"))
        #expect(environment.contains("RCLONE_DRIVE_CLIENT_SECRET=\(GoogleClient.test.secret)\n"))
        #expect(environment.contains("RCLONE_DRIVE_SCOPE=drive.file\n"))
        #expect(try String(contentsOf: drives.root.appending(path: "authorize-arguments"), encoding: .utf8).hasPrefix("authorize drive "))
    }

    @Test func signInWithoutAnAccountFromDriveReturnsNoToken() async throws {
        let drives = try signInDrives(token: #"{"access_token":"ya29.unknown","refresh_token":"1//r"}"#)
        defer { drives.remove() }

        await #expect { try await drives.service.signInWithGoogle(for: .googleDrive) } throws: {
            $0.localizedDescription == String(localized: .googleSignInFailed)
        }
    }

    @Test func cloudStorageSignInStaysOnItsOwnScopeWithNoAccount() async throws {
        let drives = try signInDrives(token: #"{"access_token":"ya29.unknown","refresh_token":"1//r"}"#)
        defer { drives.remove() }

        let signIn = try await drives.service.signInWithGoogle(for: .gcs)

        #expect(signIn.accountID.isEmpty)
        let environment = try String(contentsOf: drives.root.appending(path: "authorize-env"), encoding: .utf8)
        #expect(environment.contains("RCLONE_GCS_CLIENT_ID=") && !environment.contains("SCOPE"))
    }

    @Test func connectionTestGivesRcloneTheSignInButNotInItsArguments() async throws {
        let drives = try StubbedDrives("drive-test") { root in
            """
            if [ "$1" = 'lsf' ]; then
                printf '%s\\n' "$*" > '\(root.path)/lsf-arguments'
                env | grep '^RCLONE_' | sort > '\(root.path)/lsf-environment'
            fi
            """
        }
        defer { drives.remove() }

        try await drives.service.test(Connection.googleDrive(), credentials: Credentials.google())

        let environment = try String(contentsOf: drives.root.appending(path: "lsf-environment"), encoding: .utf8)
        #expect(environment.contains("_TOKEN=\(googleTokenJSON)\n"))
        #expect(environment.contains("_CLIENT_ID=\(GoogleClient.test.id)\n"))
        #expect(environment.contains("_SCOPE=drive.file\n"))
        let arguments = try String(contentsOf: drives.root.appending(path: "lsf-arguments"), encoding: .utf8)
        #expect(arguments.contains("unlocalfs-drive:UnlocalFS") && !arguments.contains("refresh"))
    }

    @Test(arguments: [
        (Connection.googleDrive(), Credentials.google(), "error listing: directory not found", true),
        (Connection.googleDrive(), Credentials.google(), "googleapi: Error 403: Rate Limit Exceeded", false),
        (Connection.gcs(authentication: .googleAccount), Credentials.google(), "error listing: directory not found", false),
        (Connection.s3(), Credentials.s3(), "error listing: directory not found", false),
    ])
    func onlyGoogleDriveTreatsAMissingFolderAsEmpty(connection: Connection, credentials: Credentials, failure: String, passes: Bool) async throws {
        let drives = try StubbedDrives("drive-test") { _ in
            """
            if [ "$1" = 'lsf' ]; then echo '\(failure)' >&2; exit 1; fi
            """
        }
        defer { drives.remove() }

        var passed = true
        do { try await drives.service.test(connection, credentials: credentials) } catch { passed = false }

        #expect(passed == passes)
    }

    @Test func exportAlwaysCarriesTheClientButTheTokenOnlyWithTheSignIn() async throws {
        try await withOfflineDrive(Connection.googleDrive { $0.encrypted = true }) { drive in
            let credentials = Credentials(encryptionPassword: "crypt", googleToken: googleTokenJSON, googleAccountID: "account-1")
            let withSignIn = drive.paths.config.deletingLastPathComponent().appending(path: "with.conf")
            let withoutSignIn = drive.paths.config.deletingLastPathComponent().appending(path: "without.conf")
            try await drive.service.exportRcloneConfig(drive.connection, credentials: credentials, to: withSignIn)
            try await drive.service.exportRcloneConfig(drive.connection, credentials: nil, to: withoutSignIn)

            let remote = try #require(try await dump(drive, withSignIn)["unlocalfs-drive"])
            #expect(remote["token"] == googleTokenJSON && remote["scope"] == "drive.file")
            #expect(remote["client_id"] == GoogleClient.test.id && remote["client_secret"] == GoogleClient.test.secret)
            #expect(try await dump(drive, withSignIn)["unlocalfs"]?["remote"] == "unlocalfs-drive:UnlocalFS")
            let bare = try #require(try await dump(drive, withoutSignIn)["unlocalfs-drive"])
            #expect(bare["token"] == nil && bare["scope"] == "drive.file")
            #expect(bare["client_id"] == GoogleClient.test.id && bare["client_secret"] == GoogleClient.test.secret)
            #expect(try !String(contentsOf: withoutSignIn, encoding: .utf8).contains("refresh"))
        }
    }
}

private func signInDrives(token: String) throws -> StubbedDrives {
    try StubbedDrives("drive-sign-in") { root in
        """
        if [ "$1" = 'authorize' ]; then
            env | grep '^RCLONE_' | sort > '\(root.path)/authorize-env'
            printf '%s\\n' "$*" > '\(root.path)/authorize-arguments'
            printf 'Paste the following into your remote machine --->\\n%s\\n<---End paste\\n' '\(token)'
        fi
        """
    }
}

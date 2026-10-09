import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite(.timeLimit(.minutes(2))) struct SFTPDriveTests {
    @Test(arguments: SFTPLogin.allCases)
    func driveDownloadsUploadsAndDeletesFiles(login: SFTPLogin) async throws {
        try await withSFTPDrive(login) { drive, sftp in
            try await verifyRoundTrip(drive, storage: sftp.served, credentials: sftp.credentials)
        }
    }

    @Test func newOrChangedServerKeyNeedsApprovalBeforeConnecting() async throws {
        try await withSFTPDrive(trusted: false) { drive, sftp in
            let credentials = sftp.credentials
            let first = try await #require(throws: ServerTrustChallenge.self) { try await drive.service.test(drive.connection, credentials: credentials) }
            let fingerprint = try await Command.run(URL(filePath: "/usr/bin/ssh-keygen"), ["-lf", sftp.keys.appending(path: "host.pub").path])
            #expect(first.fingerprints.contains(try #require(String(decoding: fingerprint, as: UTF8.self).split(separator: " ").dropFirst().first)))
            #expect(!first.keyChanged)
            try await drive.service.trustServer(first)
            try await drive.service.test(drive.connection, credentials: credentials)

            try await sftp.restartServer(hostKey: "other-host")
            let changed = try await #require(throws: ServerTrustChallenge.self) { try await drive.service.test(drive.connection, credentials: credentials) }
            #expect(changed.keyChanged)
            await #expect(throws: ServerTrustChallenge.self) { try await drive.service.mount(drive.connection, credentials: credentials) }
            try await drive.service.trustServer(changed)
            try await drive.service.test(drive.connection, credentials: credentials)
        }
    }
}

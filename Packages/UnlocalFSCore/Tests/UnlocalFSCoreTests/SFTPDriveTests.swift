import Darwin
import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSTestSupport

@Suite(.timeLimit(.minutes(2))) struct SFTPDriveTests {
    @Test(arguments: SFTPLogin.allCases)
    func driveDownloadsUploadsAndDeletesFiles(login: SFTPLogin) async throws {
        try await withSFTPDrive(login) { drive, sftp in
            try await verifyRoundTrip(drive, storage: sftp.served, credentials: sftp.credentials)
        }
    }

    @Test func driveReconnectsAfterMountProcessExits() async throws {
        try await withSFTPDrive { drive, sftp in
            try Data("from the server".utf8).write(to: sftp.served.appending(path: "remote.txt"))
            try await drive.service.mount(drive.connection, credentials: sftp.credentials)
            let savedPID = try String(contentsOf: drive.paths.pidFile(drive.connection), encoding: .utf8)
            let pid = try #require(pid_t(savedPID))
            try #require(kill(pid, SIGKILL) == 0)
            try await waitUntil(timeout: .seconds(5)) { await !drive.service.status(drive.connection).isRunning }
            #expect(await drive.service.status(drive.connection).isMounted)

            try await drive.service.reconnect(drive.connection, credentials: sftp.credentials)
            #expect(try String(contentsOf: drive.mounted.appending(path: "remote.txt"), encoding: .utf8) == "from the server")
            try await drive.service.unmount(drive.connection)
            #expect(await !drive.service.status(drive.connection).isActive)
        }
    }

    @Test func newOrChangedServerKeyNeedsApprovalBeforeConnecting() async throws {
        try await withSFTPDrive(trusted: false) { drive, sftp in
            let credentials = sftp.credentials
            let first = try await #require(throws: ServerTrustChallenge.self) { try await drive.service.test(drive.connection, credentials: credentials) }
            let fingerprint = try await Command.run(URL(filePath: "/usr/bin/ssh-keygen"), ["-lf", sftp.keys.appending(path: "host.pub").path])
            #expect(try first.fingerprints.contains(#require(String(decoding: fingerprint, as: UTF8.self).split(separator: " ").dropFirst().first)))
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

    @Test func exportKeepsHostVerificationAndNeedsNoLocalFiles() async throws {
        let connection = Connection.sftp {
            $0.encrypted = true
            $0.sftp.remotePath = "/srv/files"
            $0.sftp.authentication = .privateKey
            $0.sftp.keyFile = "/nonexistent/id_ed25519"
            $0.sftp.agentSocket = "/tmp/agent.sock"
        }
        try await withOfflineDrive(connection) { drive in
            let repository = SavedConnectionRepository(store: ConnectionStore(url: drive.paths.config), credentials: MemoryCredentialStorage())
            try await repository.save(connection, credentials: drive.service.prepareCredentials(Credentials(encryptionPassword: "crypt", keyPassphrase: "phrase")))
            let export = ExportRcloneConfigUseCase(repository: repository, drives: drive.service)
            let folder = drive.paths.config.deletingLastPathComponent()
            let withSecrets = folder.appending(path: "with.conf")
            let withoutSecrets = folder.appending(path: "without.conf")
            try await export.execute(connection, to: withSecrets, includesSecrets: true)
            try await export.execute(connection, to: withoutSecrets, includesSecrets: false)

            let remotes = try await dump(drive, withSecrets)
            let sftp = try #require(remotes["unlocalfs-sftp"])
            #expect(sftp["host"] == "files.example.com" && sftp["user"] == "me")
            #expect(sftp["known_hosts_file"] == drive.knownHosts.path && sftp["key_file"] == "/nonexistent/id_ed25519")
            #expect(!sftp.values.contains("/tmp/agent.sock"))
            #expect(remotes["unlocalfs"]?["remote"] == "unlocalfs-sftp:/srv/files")
            let passphrase = try #require(sftp["key_file_pass"])
            let password = try #require(remotes["unlocalfs"]?["password"])
            #expect(passphrase != "phrase" && password != "crypt")
            let bare = try await dump(drive, withoutSecrets)
            #expect(bare["unlocalfs-sftp"]?["key_file_pass"] == nil && bare["unlocalfs"]?["password"] == nil)
        }
    }
}

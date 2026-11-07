import Darwin
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

    @Test func multiConnectionUploadsKeepTheCacheAndUseLargeWriteBuffersOnlyWhenChosen() async throws {
        try await withSFTPDrive { drive, sftp in
            let credentials = try await drive.service.prepareCredentials(sftp.credentials)
            var mounts: [(streams: Int, bufferSize: Int)] = []
            for multiConnection in [false, true] {
                var connection = drive.connection
                connection.multiThreadUploads = multiConnection
                try await drive.service.mount(connection, credentials: credentials)
                let main = try await drive.control("options/get", "blocks=main")["main"] as? [String: Any]
                let streams = try #require(main?["MultiThreadStreams"] as? Int)
                let bufferSize = try #require(main?["MultiThreadWriteBufferSize"] as? Int)
                mounts.append((streams, bufferSize))
                try await drive.service.unmount(connection)
            }
            #expect(mounts.map(\.streams) == [1, 4])
            #expect(mounts.map(\.bufferSize) == [131_072, 4_194_304])
            let caches = try FileManager.default.contentsOfDirectory(atPath: drive.paths.cache(drive.connection).appending(path: "vfs").path)
            #expect(caches.count == 1)
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
}

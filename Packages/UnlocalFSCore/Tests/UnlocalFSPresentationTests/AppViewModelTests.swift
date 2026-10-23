import Foundation
import Testing
@testable import UnlocalFSDomain
import UnlocalFSTestSupport
import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation

@MainActor @Suite final class AppViewModelTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func activatingACheckingDriveDoesNothing() async throws {
        let connection = Connection.s3()
        try fixture.repository.save(connection, credentials: Credentials.s3())
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.activate(connection)

        #expect(desktop.openedDrives.isEmpty)
        #expect(app.problem(connection) == nil)
        #expect(app.statusText(connection) == String(localized: .checking))
    }

    @Test func activatingAnEjectedDriveKeepsItsServiceRunning() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        await app.refresh()

        await app.activate(connection)

        #expect(desktop.openedDrives.isEmpty)
        #expect(app.problem(connection) == nil)
        #expect(await fixture.service.status(connection).isRunning)
    }

    @Test func failedActivationShowsTheConnectErrorWithoutOpeningFinder() async throws {
        let connection = Connection.s3()
        try fixture.repository.save(connection, credentials: Credentials.s3())
        try "Connection failed".write(to: fixture.root.appending(path: "test-error"), atomically: true, encoding: .utf8)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        await app.refresh()

        await app.activate(connection)

        #expect(desktop.openedDrives.isEmpty)
        #expect(app.problem(connection)?.contains("Connection failed") == true)
        #expect(!app.isActive(connection))
    }

    @Test func savePublishesTheSavedConnectionAndSelection() async throws {
        let app = fixture.app()
        let connection = Connection.s3()
        let editor = fixture.editor(draft: .init(connection: connection), app: app)
        editor.credentials = Credentials.s3()

        #expect(await editor.save())

        #expect(app.selected == connection)
        #expect(try fixture.repository.all() == app.connections)
        #expect(try fixture.repository.credentials(for: connection.id) == editor.credentials)
        #expect(app.statuses[connection.id] == MountStatus())
    }

    @Test func deletingADriveKeepsTrafficSelectedOrSelectsTheFirstRemainingDrive() async throws {
        let first = Connection.s3 { $0.name = "First" }
        let second = Connection.s3 { $0.name = "Second" }
        let third = Connection.s3 { $0.name = "Third" }
        for connection in [first, second, third] { try fixture.repository.save(connection, credentials: Credentials()) }
        let app = fixture.app()
        #expect(app.selection == .drive(first.id))

        app.selection = .traffic
        await app.delete(second)
        #expect(app.selection == .traffic)
        #expect(app.selected == nil)

        app.selection = .drive(third.id)
        await app.delete(third)
        #expect(app.selected == first)
    }

    @Test func failedUploadsNeedAttentionAndNotifyOnce() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection, failed: 1, lastError: "AccessDenied: Access Denied")
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.refresh()
        await app.refresh()

        #expect(app.indicator(connection) == .attention)
        #expect(app.statusText(connection) == String(localized: .uploadNeedsAttention))
        #expect(app.uploadFailure(connection)?.uploadError == "AccessDenied: Access Denied")
        #expect(desktop.notifications.map(\.title) == [String(localized: .uploadsFailed("My files"))])
        #expect(desktop.notifications.map(\.body) == [String(localized: .uploadsFailedReason("AccessDenied: Access Denied"))])

        await app.disconnect(connection)
        #expect(app.problem(connection) != nil)
        #expect(app.uploadFailure(connection)?.uploadError == "AccessDenied: Access Denied")

        try fixture.queue()
        await app.refresh()

        #expect(app.uploadFailure(connection) == nil)
        #expect(app.statusText(connection) != String(localized: .uploadNeedsAttention))
    }

    @Test func failedUploadsWithoutAReasonStillNeedAttention() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection, failed: 1)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.refresh()

        #expect(try #require(app.uploadFailure(connection)).uploadError == nil)
        #expect(desktop.notifications.map(\.body) == [String(localized: .uploadsFailedBody)])
    }

    @Test func pendingUploadsExplainBlockedDisconnectAndNotifyWhenFinished() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection, queued: 1, cached: 2048)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.refresh()

        #expect(app.indicator(connection) == .idle)
        #expect(app.statusText(connection) == String(localized: .uploadsPending(1)))
        #expect(app.servingStatus(connection)?.bytesCached == 2048)
        #expect(!app.isShowingUploadsBlockingDisconnect)
        #expect(desktop.notifications.isEmpty)

        await app.disconnect(connection)

        #expect(app.problem(connection) == nil)
        #expect(await fixture.service.status(connection).isRunning)
        #expect(app.uploadsBlockingDisconnect == connection)
        #expect(app.uploadsBlockingMessage(connection) == String(localized: .uploadsPendingKeepAppRunning))
        #expect(app.needsMainWindow(connection))

        app.isShowingUploadsBlockingDisconnect = false
        #expect(!app.needsMainWindow(connection))
        try fixture.serve(connection)
        await app.refresh()
        await app.refresh()

        #expect(desktop.notifications.map(\.title) == [String(localized: .finishedUploading(connection.name))])
        #expect(desktop.notifications.map(\.body) == [String(localized: .canDisconnectNow)])
        #expect(await fixture.service.status(connection).isRunning)
    }

    @Test func uploadsInProgressAreNotReportedAsFailed() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection, queued: 1)
        try fixture.queue(#"{"name":"a.dmg","size":4096,"expiry":-1,"tries":1,"uploading":true}"#)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.refresh()

        #expect(app.statusText(connection) == String(localized: .uploadsPending(1)))
        #expect(desktop.notifications.isEmpty)
    }

    @Test func activeDriveShowsTheNetworkIsUnavailable() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection)
        let app = fixture.app()

        await app.networkChanged(available: false)

        #expect(app.isOffline(connection))
        #expect(app.indicator(connection) == .attention)
        #expect(app.statusText(connection) == String(localized: .networkUnavailable))
    }

    @Test func connectAndDisconnectFollowTheConnectionState() async throws {
        let idle = Connection.s3()
        let connected = Connection.s3()
        try ConnectionStore(url: fixture.paths.config).save(idle)
        try fixture.serve(connected)
        let app = fixture.app()
        #expect(!app.isDisconnected(idle))

        await app.refresh()

        #expect(app.isDisconnected(idle))
        #expect(!app.isDisconnected(connected))
        #expect(app.canConnect(idle))
        #expect(!app.canDisconnect(idle))
        #expect(!app.canConnect(connected))
        #expect(app.canDisconnect(connected))
    }

    @Test func driveThatNeedsReconnectCanNeitherConnectNorDisconnect() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection)
        try Data("unavailable".utf8).write(to: fixture.root.appending(path: "vfs-stats.json"))
        let app = fixture.app()

        await app.refresh()

        #expect(app.needsReconnect(connection))
        #expect(!app.canConnect(connection))
        #expect(!app.canDisconnect(connection))
    }

    @Test func disconnectAllStopsAtTheFirstDriveWithPendingUploads() async throws {
        let first = Connection.s3()
        let second = Connection.s3(name: "Second drive")
        try fixture.serve(first, queued: 1)
        try fixture.serve(second, queued: 1)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        await app.refresh()
        let blocked = try #require(app.connections.first)

        await app.disconnectAll()

        #expect(app.uploadsBlockingDisconnect == blocked)
        #expect(app.selected == blocked)

        try fixture.serve(blocked)
        await app.refresh()

        #expect(desktop.notifications.map(\.title) == [String(localized: .finishedUploading(blocked.name))])
    }

    @Test func checkAgainClearsTheErrorAndReloadsTheStatus() async throws {
        let connection = Connection.s3()
        try ConnectionStore(url: fixture.paths.config).save(connection)
        let app = fixture.app()
        await app.refreshFiles(connection)
        #expect(app.problem(connection) != nil)
        #expect(app.statusText(connection) == String(localized: .needsAttention))

        await app.checkAgain(connection)

        #expect(app.problem(connection) == nil)
        #expect(app.statusText(connection) == String(localized: .disconnected))
    }

    @Test func cancellingTheExportWritesNothing() async throws {
        let connection = try fixture.saveEncryptedConnection()
        let app = fixture.app()

        await app.exportRcloneConfig(connection)

        #expect(app.alert == nil)
        #expect(fixture.rcloneCalls.isEmpty)
    }

    @Test(arguments: ["unlocalfs-s3", "unlocalfs"])
    func failedExportKeepsTheDestinationAndShowsAnAlertWithoutSecrets(remote: String) async throws {
        let connection = try fixture.saveEncryptedConnection()
        try remote.write(to: fixture.root.appending(path: "config-error"), atomically: true, encoding: .utf8)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let destination = fixture.root.appending(path: "My files rclone.conf")
        try Data("original".utf8).write(to: destination)
        desktop.rcloneConfigDestination = RcloneConfigDestination(url: destination, includesSecrets: true)
        let app = fixture.app(desktop: desktop)

        await app.exportRcloneConfig(connection)

        let alert = try #require(app.alert)
        #expect(alert.contains("Failed to create \(remote)"))
        #expect(!alert.contains("saved-"))
        #expect(!alert.contains("prepared-password"))
        #expect(try String(contentsOf: destination, encoding: .utf8) == "original")
        let config = try String(contentsOf: fixture.root.appending(path: "export-config"), encoding: .utf8)
        #expect(!FileManager.default.fileExists(atPath: URL(filePath: config).deletingLastPathComponent().path))
    }

    @Test(arguments: [true, false])
    func sftpExportKeepsHostVerificationAndNeverReadsLocalFiles(includesSecrets: Bool) async throws {
        let connection = Connection.sftp {
            $0.encrypted = true
            $0.sftp.remotePath = "/srv/files"
            $0.sftp.authentication = .privateKey
            $0.sftp.keyFile = "/nonexistent/id_ed25519"
            $0.sftp.agentSocket = "/tmp/agent.sock"
        }
        try fixture.repository.save(connection, credentials: Credentials(encryptionPassword: "saved-password", keyPassphrase: "saved-phrase"))
        let desktop = TestDesktopServices(paths: fixture.paths)
        let destination = fixture.root.appending(path: "My files rclone.conf")
        desktop.rcloneConfigDestination = RcloneConfigDestination(url: destination, includesSecrets: includesSecrets)
        let app = fixture.app(desktop: desktop)

        await app.exportRcloneConfig(connection)

        #expect(app.alert == nil)
        let arguments = try String(contentsOf: fixture.root.appending(path: "config-arguments"), encoding: .utf8)
        let sftp = try #require(arguments.split(separator: "\n").first { $0.hasPrefix("config create unlocalfs-sftp sftp") })
        #expect(sftp.contains("host=files.example.com") && sftp.contains("user=me") && sftp.contains("shell_type=none"))
        #expect(sftp.contains("known_hosts_file=\(fixture.paths.support.appending(path: "known_hosts").path)") && sftp.contains("key_file=/nonexistent/id_ed25519"))
        #expect(!sftp.contains("/tmp/agent.sock") && !sftp.contains("saved-"))
        #expect(sftp.contains("key_file_pass=prepared-password") == includesSecrets)
        #expect(arguments.contains("config create unlocalfs crypt") && arguments.contains("remote=unlocalfs-sftp:/srv/files"))
        #expect(arguments.contains("password=prepared-password") == includesSecrets)
        #expect(try String(contentsOf: destination, encoding: .utf8).contains("[unlocalfs-sftp]"))
    }

    @Test func unencryptedDrivesCannotExportAConfig() async throws {
        let connection = Connection.s3()
        try fixture.repository.save(connection, credentials: Credentials(accessKey: "saved-access", secretKey: "saved-secret"))
        let export = ExportRcloneConfigUseCase(repository: fixture.repository, drives: fixture.service)

        await #expect(throws: AppError.self) {
            try await export.execute(connection, to: fixture.root.appending(path: "My files rclone.conf"), includesSecrets: true)
        }
        #expect(fixture.rcloneCalls.isEmpty)
    }

    @Test func loginFailureKeepsTheSystemStateAndShowsAnError() throws {
        let desktop = TestDesktopServices(paths: fixture.paths)
        desktop.loginError = AppError("Login registration failed")
        let app = fixture.app(desktop: desktop)

        app.setOpensAtLogin(true)

        #expect(!app.opensAtLogin)
        #expect(app.alert == "Login registration failed")
    }
}

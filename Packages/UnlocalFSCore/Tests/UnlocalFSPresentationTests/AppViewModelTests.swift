import Foundation
import Testing
@testable import UnlocalFSDomain
import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation

@MainActor @Suite struct AppViewModelTests {
    @Test func activatingACheckingDriveDoesNothing() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try fixture.repository.save(connection, credentials: Credentials(accessKey: "key", secretKey: "secret"))
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.activate(connection)

        #expect(desktop.openedDrives.isEmpty)
        #expect(app.problem(connection) == nil)
        #expect(app.statusText(connection) == String(localized: .checking))
    }

    @Test func activatingAnEjectedDriveKeepsItsServiceRunning() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
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
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try fixture.repository.save(connection, credentials: Credentials(accessKey: "key", secretKey: "secret"))
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
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let app = fixture.app()
        let connection = connectionFixture()
        let editor = fixture.editor(draft: .init(connection: connection), app: app)
        editor.credentials = Credentials(accessKey: "key", secretKey: "secret")

        #expect(await editor.save())

        #expect(app.selected == connection)
        #expect(try fixture.repository.all() == app.connections)
        #expect(try fixture.repository.credentials(for: connection.id) == editor.credentials)
        #expect(app.statuses[connection.id] == MountStatus())
    }

    @Test func quitShowsWhyActiveDrivesMustDisconnect() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        try fixture.serve(connectionFixture())
        let app = fixture.app()

        #expect(await !app.canQuit())

        #expect(app.alert == String(localized: .disconnectBeforeQuitting))
    }

    @Test func failedUploadsNeedAttentionAndNotifyOnce() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try fixture.serve(connection, failed: 1)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.refresh()
        await app.refresh()

        #expect(app.indicator(connection) == .attention)
        #expect(app.statusText(connection) == String(localized: .uploadNeedsAttention))
        #expect(desktop.notifications.map(\.title) == [String(localized: .uploadsFailed("My files"))])
    }

    @Test func pendingUploadsExplainBlockedDisconnectAndNotifyWhenFinished() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
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
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try fixture.serve(connection, queued: 1)
        try fixture.queue(#"{"name":"a.dmg","size":4096,"tries":1,"uploading":true}"#)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.refresh()

        #expect(app.statusText(connection) == String(localized: .uploadsPending(1)))
        #expect(desktop.notifications.isEmpty)
    }

    @Test func activeDriveShowsTheNetworkIsUnavailable() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try fixture.serve(connection)
        let app = fixture.app()

        await app.networkChanged(available: false)

        #expect(app.isOffline(connection))
        #expect(app.indicator(connection) == .attention)
        #expect(app.statusText(connection) == String(localized: .networkUnavailable))
    }

    @Test func connectAndDisconnectFollowTheConnectionState() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let idle = connectionFixture()
        let connected = connectionFixture()
        try ConnectionStore(url: fixture.paths.config).save(idle)
        try fixture.serve(connected)
        let app = fixture.app()

        await app.refresh()

        #expect(app.canConnect(idle))
        #expect(!app.canDisconnect(idle))
        #expect(!app.canConnect(connected))
        #expect(app.canDisconnect(connected))
    }

    @Test func driveThatNeedsReconnectCanNeitherConnectNorDisconnect() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try ConnectionStore(url: fixture.paths.config).save(connection)
        try Data().write(to: fixture.paths.socket(connection))
        let app = fixture.app()

        await app.refresh()

        #expect(app.needsReconnect(connection))
        #expect(!app.canConnect(connection))
        #expect(!app.canDisconnect(connection))
    }

    @Test func disconnectAllWithNothingConnectedDoesNotAsk() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        try ConnectionStore(url: fixture.paths.config).save(connectionFixture())
        let app = fixture.app()
        await app.refresh()

        app.requestDisconnectAll()

        #expect(!app.isConfirmingDisconnectAll)
    }

    @Test func disconnectAllAsksWhenAnyDriveIsConnected() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let idle = connectionFixture()
        let connected = connectionFixture()
        try ConnectionStore(url: fixture.paths.config).save(idle)
        try fixture.serve(connected)
        let app = fixture.app()
        await app.refresh()

        app.requestDisconnectAll()

        #expect(app.isConfirmingDisconnectAll)
    }

    @Test func disconnectAllStopsAtTheFirstDriveWithPendingUploads() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let first = connectionFixture()
        var second = connectionFixture()
        second.name = "Second drive"
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
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try ConnectionStore(url: fixture.paths.config).save(connection)
        let app = fixture.app()
        await app.refreshFiles(connection)
        #expect(app.problem(connection) != nil)
        #expect(app.statusText(connection) == String(localized: .needsAttention))

        await app.checkAgain(connection)

        #expect(app.problem(connection) == nil)
        #expect(app.statusText(connection) == String(localized: .disconnected))
    }

    @Test func failedSharesKeepTheClipboardAndExplainWhy() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let encrypted = try fixture.saveEncryptedConnection()
        let desktop = TestDesktopServices(paths: fixture.paths)
        let previousLink = URL(string: "https://example.com/previous")!
        desktop.copiedLinks = [previousLink]
        let app = fixture.app(desktop: desktop)

        await app.copyShareLinks(for: [fixture.root.appending(path: "outside.jpg")], expiry: .day)

        #expect(desktop.copiedLinks == [previousLink])
        let outside = try #require(desktop.notifications.first)
        #expect(outside.title == String(localized: .couldNotCopyLink("outside.jpg")))
        #expect(outside.fallbackToAlert)

        await app.copyShareLinks(for: [fixture.paths.mount(encrypted).appending(path: "plan.pdf")], expiry: .day)

        #expect(desktop.copiedLinks == [previousLink])
        let notification = try #require(desktop.notifications.last)
        #expect(notification.title == String(localized: .couldNotCopyLink("plan.pdf")))
        #expect(notification.body == String(localized: .linksUnavailableEncrypted))
        #expect(!FileManager.default.fileExists(atPath: fixture.root.appending(path: "process-calls").path))
    }

    @Test func cancellingTheExportWritesNothing() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = try fixture.saveEncryptedConnection()
        let app = fixture.app()

        await app.exportRcloneConfig(connection)

        #expect(app.alert == nil)
        #expect(!FileManager.default.fileExists(atPath: fixture.root.appending(path: "process-calls").path))
    }

    @Test(arguments: ["unlocalfs-s3", "unlocalfs"])
    func failedExportKeepsTheDestinationAndShowsAnAlertWithoutSecrets(remote: String) async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
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
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        var connection = sftpConnectionFixture()
        connection.encrypted = true
        connection.sftp.remotePath = "/srv/files"
        connection.sftp.authentication = .privateKey
        connection.sftp.keyFile = "/nonexistent/id_ed25519"
        connection.sftp.agentSocket = "/tmp/agent.sock"
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
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try fixture.repository.save(connection, credentials: Credentials(accessKey: "saved-access", secretKey: "saved-secret"))
        let export = ExportRcloneConfigUseCase(repository: fixture.repository, drives: fixture.service)

        await #expect(throws: AppError.self) {
            try await export.execute(connection, to: fixture.root.appending(path: "My files rclone.conf"), includesSecrets: true)
        }
        #expect(!FileManager.default.fileExists(atPath: fixture.root.appending(path: "process-calls").path))
    }

    @Test func loginFailureKeepsTheSystemStateAndShowsAnError() throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let desktop = TestDesktopServices(paths: fixture.paths)
        desktop.loginError = AppError("Login registration failed")
        let app = fixture.app(desktop: desktop)

        app.setOpensAtLogin(true)

        #expect(!app.opensAtLogin)
        #expect(app.alert == "Login registration failed")
    }
}

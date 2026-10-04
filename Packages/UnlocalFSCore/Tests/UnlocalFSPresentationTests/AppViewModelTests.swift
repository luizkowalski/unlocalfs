import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

@MainActor @Suite struct AppViewModelTests {
    init() { pinEnglish() }

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
        #expect(app.statusText(connection) == "Checking…")
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

        #expect(app.alert?.hasPrefix("Disconnect your drives before quitting.") == true)
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
        #expect(app.statusText(connection) == "Upload needs attention")
        #expect(app.uploadNotice(connection) == nil)
        #expect(desktop.notifications.map(\.title) == ["Uploads failed on My files"])
    }

    @Test func pendingUploadsOnAnEjectedDriveAskToKeepTheAppRunning() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try fixture.serve(connection, queued: 1, cached: 2048)
        let app = fixture.app()

        await app.refresh()

        #expect(app.indicator(connection) == .idle)
        #expect(app.statusText(connection) == "1 upload pending")
        #expect(app.uploadNotice(connection) == "Uploads pending. Keep UnlocalFS running until they finish, then disconnect again.")
        #expect(app.servingStatus(connection)?.bytesCached == 2048)
    }

    @Test func pendingUploadsReportTheBytesWaitingToUpload() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try fixture.serve(connection, queued: 2, cached: 4096)
        try fixture.queue(
            #"{"name":"a.pdf","size":1500,"tries":1,"uploading":true}"#,
            #"{"name":"b.pdf","size":500,"tries":0,"uploading":false}"#)
        let app = fixture.app()

        await app.refresh()

        #expect(app.servingStatus(connection)?.pendingBytes == 2000)
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

        #expect(app.statusText(connection) == "1 upload pending")
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
        #expect(app.statusText(connection) == "Network unavailable")
    }

    @Test func checkAgainClearsTheErrorAndReloadsTheStatus() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        try ConnectionStore(url: fixture.paths.config).save(connection)
        let app = fixture.app()
        await app.refreshFiles(connection)
        #expect(app.problem(connection) != nil)
        #expect(app.statusText(connection) == "Needs attention")

        await app.checkAgain(connection)

        #expect(app.problem(connection) == nil)
        #expect(app.statusText(connection) == "Disconnected")
    }

    @Test func failedShareKeepsTheClipboardAndReportsTheFile() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let desktop = TestDesktopServices(paths: fixture.paths)
        let previousLink = URL(string: "https://example.com/previous")!
        desktop.copiedLinks = [previousLink]
        let app = fixture.app(desktop: desktop)

        await app.copyShareLinks(for: [fixture.root.appending(path: "outside.jpg")], expiry: .day)

        #expect(desktop.copiedLinks == [previousLink])
        let notification = try #require(desktop.notifications.first)
        #expect(notification.title == "Could not copy a link to outside.jpg")
        #expect(notification.fallbackToAlert)
    }

    @Test func sharingFromAnEncryptedDriveExplainsWhyWithoutCreatingALink() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = try fixture.saveEncryptedConnection()
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.copyShareLinks(for: [fixture.paths.mount(connection).appending(path: "plan.pdf")], expiry: .day)

        #expect(desktop.copiedLinks.isEmpty)
        let notification = try #require(desktop.notifications.first)
        #expect(notification.title == "Could not copy a link to plan.pdf")
        #expect(notification.body.contains("encrypted drives"))
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
        var connection = try fixture.sftpConnection()
        connection.encrypted = true
        connection.sftp.remotePath = "/srv/files"
        connection.sftp.authentication = .privateKey
        connection.sftp.keyFile = "/nonexistent/id_ed25519"
        connection.sftp.trustedHostsFile = "/nonexistent/known_hosts"
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
        #expect(sftp.contains("known_hosts_file=/nonexistent/known_hosts") && sftp.contains("key_file=/nonexistent/id_ed25519"))
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

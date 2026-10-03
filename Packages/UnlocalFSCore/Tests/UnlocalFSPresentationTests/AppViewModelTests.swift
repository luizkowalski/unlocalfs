import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

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
        #expect(app.isServing(connection))
        #expect(app.cachedBytes(connection) == 2048)
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

    @Test func exportWithoutSecretsWritesTheConfigWithoutReadingSavedCredentials() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = try fixture.saveEncryptedConnection()
        let desktop = TestDesktopServices(paths: fixture.paths)
        let destination = fixture.root.appending(path: "My files rclone.conf")
        desktop.rcloneConfigDestination = (destination, false)
        let app = fixture.app(desktop: desktop)

        await app.exportRcloneConfig(connection)

        #expect(app.alert == nil)
        #expect(try String(contentsOf: destination, encoding: .utf8) == "[unlocalfs-s3]\n[unlocalfs]\n")
        let arguments = try fixture.configArguments()
        #expect(!arguments.contains("saved-"))
        #expect(!arguments.contains("prepared-password"))
    }

    @Test func exportWithSecretsIncludesSavedKeysAndTheObscuredPassword() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = try fixture.saveEncryptedConnection()
        let desktop = TestDesktopServices(paths: fixture.paths)
        desktop.rcloneConfigDestination = (fixture.root.appending(path: "My files rclone.conf"), true)
        let app = fixture.app(desktop: desktop)

        await app.exportRcloneConfig(connection)

        #expect(app.alert == nil)
        let arguments = try fixture.configArguments()
        #expect(arguments.contains("access_key_id=saved-access"))
        #expect(arguments.contains("secret_access_key=saved-secret"))
        #expect(arguments.contains("password=prepared-password"))
        #expect(!arguments.contains("saved-password"))
    }

    @Test func cancellingTheExportWritesNothing() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = try fixture.saveEncryptedConnection()
        let app = fixture.app()

        await app.exportRcloneConfig(connection)

        #expect(app.alert == nil)
        #expect(!FileManager.default.fileExists(atPath: fixture.root.appending(path: "config-arguments").path))
    }

    @Test func failedExportShowsAnAlertWithoutSecrets() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = try fixture.saveEncryptedConnection()
        FileManager.default.createFile(atPath: fixture.root.appending(path: "config-error").path, contents: nil)
        let desktop = TestDesktopServices(paths: fixture.paths)
        desktop.rcloneConfigDestination = (fixture.root.appending(path: "My files rclone.conf"), true)
        let app = fixture.app(desktop: desktop)

        await app.exportRcloneConfig(connection)

        let alert = try #require(app.alert)
        #expect(alert.contains("config"))
        #expect(!alert.contains("saved-"))
        #expect(!alert.contains("prepared-password"))
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
        #expect(!FileManager.default.fileExists(atPath: fixture.root.appending(path: "config-arguments").path))
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

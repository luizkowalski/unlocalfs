import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

@MainActor @Suite struct AppViewModelTests {
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

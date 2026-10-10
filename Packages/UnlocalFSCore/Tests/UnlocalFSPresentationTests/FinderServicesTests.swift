import Foundation
import Testing
@testable import UnlocalFSDomain
import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation

@MainActor @Suite struct FinderServicesTests {
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

    @Test func refusedDuplicateNamesTheFileAndExplainsWhy() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let server = sftpConnectionFixture()
        try fixture.repository.save(server, credentials: Credentials(password: "secret"))
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.duplicateOnServer([fixture.paths.mount(server).appending(path: "plan.pdf")])

        let notification = try #require(desktop.notifications.last)
        #expect(notification.title == String(localized: .couldNotDuplicate("plan.pdf")))
        #expect(notification.body.contains(server.provider.title))
        #expect(notification.fallbackToAlert)
        #expect(!FileManager.default.fileExists(atPath: fixture.root.appending(path: "process-calls").path))
    }
}

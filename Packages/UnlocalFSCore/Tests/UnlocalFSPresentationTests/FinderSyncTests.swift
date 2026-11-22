import Foundation
import Testing
@testable import UnlocalFSDomain
import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite(.timeLimit(.minutes(1))) final class FinderSyncTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func aQueueChangeReachesTheSnapshotAndIsAnnouncedOnce() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        await app.refresh()
        let idle = app.finderSnapshot
        #expect(idle.drives == [FinderSnapshot.Drive(mount: fixture.paths.mount(connection), uploads: [:])])
        #expect(desktop.finderChanges == 1)

        try fixture.queue(#"{"name":"photos/a.jpg","id":1,"size":1,"expiry":5,"tries":0,"uploading":false}"#)
        await app.refresh()
        #expect(app.finderSnapshot.drives.map(\.uploads) == [["photos/a.jpg": .waiting]])
        #expect(app.finderSnapshot.version != idle.version)
        #expect(desktop.finderChanges == 2)

        await app.refresh()
        #expect(desktop.finderChanges == 2)
    }

    @Test func aDriveThatStopsServingLeavesTheSnapshot() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection, queued: 1)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        await app.refresh()
        #expect(app.finderSnapshot.drives.count == 1)

        try FileManager.default.removeItem(at: fixture.paths.socket(connection))
        await app.refresh()

        #expect(app.finderSnapshot.drives.isEmpty)
        #expect(desktop.finderChanges == 2)
    }

    @Test func snapshotRequestsGetOnlyWhatChanged() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection, failed: 1)
        let app = fixture.app()
        await app.refresh()
        let snapshot = app.finderSnapshot

        #expect(app.reply(to: .snapshot(since: snapshot.version)) == .unchanged)
        #expect(app.reply(to: .snapshot(since: nil)) == .snapshot(snapshot, version: snapshot.version))
        #expect(app.reply(to: .snapshot(since: snapshot.version + 1)) == .snapshot(snapshot, version: snapshot.version))
    }

    enum Selection: CaseIterable {
        case plainFiles, encryptedFile, readOnlyFile, serverFile, fileAndFolder, twoDrives, outside, nothing
    }

    @Test(arguments: Selection.allCases)
    func theMenuOffersOnlyActionsEverySelectedFileSupports(selection: Selection) throws {
        let plain = Connection.s3(name: "Plain")
        let other = Connection.s3(name: "Other")
        let encrypted = Connection.s3(name: "Secret") { $0.encrypted = true }
        let readOnly = Connection.s3(name: "Locked") { $0.readOnly = true }
        let server = Connection.sftp(name: "Server")
        for connection in [plain, other, encrypted, readOnly, server] {
            try fixture.repository.save(connection, credentials: Credentials())
        }
        let app = fixture.app()
        func file(_ connection: Connection, _ name: String = "a.pdf") -> FinderItem {
            FinderItem(url: fixture.paths.mount(connection).appending(path: name), isFolder: false)
        }
        let links: [FinderCommand] = [.copyShareLink(.hour), .copyShareLink(.day), .copyShareLink(.week)]

        let (items, expected): ([FinderItem], [FinderCommand]) = switch selection {
        case .plainFiles: ([file(plain), file(plain, "b/c.pdf")], links + [.duplicateOnServer])
        case .encryptedFile: ([file(encrypted)], [.duplicateOnServer])
        case .readOnlyFile: ([file(readOnly)], links)
        case .serverFile: ([file(server)], [])
        case .fileAndFolder: ([file(plain), FinderItem(url: fixture.paths.mount(plain).appending(path: "b"), isFolder: true)], [])
        case .twoDrives: ([file(plain), file(other)], [])
        case .outside: ([FinderItem(url: fixture.root.appending(path: "a.pdf"), isFolder: false)], [])
        case .nothing: ([], [])
        }

        let reply = app.reply(to: .menu(items))
        #expect(reply == .menu(app.finderMenu(for: items)))
        #expect(app.finderMenu(for: items).map(\.command) == expected)
    }

    @Test func menuTitlesNameTheLinkDurations() throws {
        let plain = Connection.s3()
        try fixture.repository.save(plain, credentials: Credentials())
        let file = FinderItem(url: fixture.paths.mount(plain).appending(path: "a.pdf"), isFolder: false)

        #expect(fixture.app().finderMenu(for: [file]).map(\.title) == [
            String(localized: .copyShareLinkHour), String(localized: .copyShareLinkDay), String(localized: .copyShareLinkWeek),
            String(localized: .duplicateOnServer),
        ])
    }

    @Test func aCommandRunsTheSameWorkflowAsTheServicesEntry() async throws {
        let server = Connection.sftp()
        try fixture.repository.save(server, credentials: Credentials(password: "secret"))
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        let file = fixture.paths.mount(server).appending(path: "plan.pdf")

        #expect(app.reply(to: .run(.duplicateOnServer, files: [file])) == .accepted)
        for _ in 0 ..< 500 where desktop.notifications.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        let notification = try #require(desktop.notifications.last)
        #expect(notification.title == String(localized: .couldNotDuplicate("plan.pdf")))
        #expect(notification.body.contains(server.provider.title))
    }
}

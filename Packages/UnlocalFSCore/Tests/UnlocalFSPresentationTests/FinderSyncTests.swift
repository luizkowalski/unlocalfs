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
        #expect(try pull(app).snapshot.drives == [FinderSnapshot.Drive(mount: fixture.paths.mount(connection), uploads: [:])])
        #expect(desktop.finderChanges == 1)

        try fixture.queue(#"{"name":"photos/a.jpg","id":1,"size":1,"expiry":5,"tries":0,"uploading":false}"#)
        await app.refresh()
        #expect(try pull(app).snapshot.drives.map(\.uploads) == [["photos/a.jpg": .pending]])
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
        #expect(try pull(app).snapshot.drives.count == 1)

        try FileManager.default.removeItem(at: fixture.paths.socket(connection))
        await app.refresh()

        #expect(try pull(app).snapshot.drives.isEmpty)
        #expect(desktop.finderChanges == 2)
    }

    @Test func aDisconnectIsAnnouncedWithoutWaitingForTheNextPoll() async throws {
        let connection = Connection.s3()
        let socket = fixture.paths.socket(connection)
        try fixture.serve(connection) { request in
            switch request.method {
            case "job/list": return #"{"runningIds":[]}"#
            case "core/quit":
                try FileManager.default.removeItem(at: socket)
                return "{}"
            default: return statusBatch()
            }
        }
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        await app.refresh()

        await app.disconnect(connection)

        #expect(try pull(app).snapshot.drives.isEmpty)
        #expect(desktop.finderChanges == 2)
    }

    @Test func snapshotRequestsGetOnlyWhatChangedAndWhenTheStatusPassStarted() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection)
        let app = fixture.app()

        let beforePass = Date.now
        await app.refresh()
        let first = try pull(app)
        let checkedAt = try #require(first.checkedAt[fixture.paths.mount(connection)])
        #expect(checkedAt >= beforePass && checkedAt <= .now)
        #expect(app.reply(to: .snapshot(since: first.version)) == .unchanged(checkedAt: first.checkedAt))

        try fixture.queue(#"{"name":"a.jpg","id":1,"size":1,"expiry":5,"tries":0,"uploading":false}"#)
        await app.refresh()
        let changed = try pull(app)
        #expect(app.reply(to: .snapshot(since: first.version)) == .snapshot(changed.snapshot, version: changed.version, checkedAt: changed.checkedAt))
    }

    @Test func aPassThatSkipsABusyDriveDoesNotCountAsACheckOfIt() async throws {
        let busy = Connection.s3(name: "Busy")
        let other = Connection.s3(name: "Other")
        try fixture.serve(busy)
        try fixture.serve(other)
        let app = fixture.app()
        await app.refresh()
        let first = try pull(app).checkedAt

        app.busy.insert(busy.id)
        await app.refresh()
        let duringBusy = try pull(app).checkedAt
        #expect(duringBusy[fixture.paths.mount(busy)] == first[fixture.paths.mount(busy)])
        #expect(try #require(duringBusy[fixture.paths.mount(other)]) > #require(first[fixture.paths.mount(other)]))

        app.busy.remove(busy.id)
        await app.refresh()
        #expect(try #require(pull(app).checkedAt[fixture.paths.mount(busy)]) > #require(first[fixture.paths.mount(busy)]))
    }

    private struct Pull {
        let snapshot: FinderSnapshot
        let version: Int
        let checkedAt: [URL: Date]
    }

    private struct NoSnapshot: Error {}

    private func pull(_ app: AppViewModel) throws -> Pull {
        guard case let .snapshot(snapshot, version, checkedAt) = app.reply(to: .snapshot(since: nil)) else { throw NoSnapshot() }
        return Pull(snapshot: snapshot, version: version, checkedAt: checkedAt)
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
        func file(_ connection: Connection, _ name: String = "a.pdf") -> URL {
            fixture.paths.mount(connection).appending(path: name)
        }
        let links = [
            FinderMenuItem(title: String(localized: .copyShareLinkHour), command: .copyShareLink(.hour)),
            FinderMenuItem(title: String(localized: .copyShareLinkDay), command: .copyShareLink(.day)),
            FinderMenuItem(title: String(localized: .copyShareLinkWeek), command: .copyShareLink(.week)),
        ]
        let duplicate = FinderMenuItem(title: String(localized: .duplicateOnServer), command: .duplicateOnServer)
        let versions = FinderMenuItem(title: String(localized: .showVersions), command: .showVersions)
        let folder = fixture.paths.mount(plain).appending(path: "b", directoryHint: .isDirectory)

        let (files, expected): ([URL], [FinderMenuItem]) = switch selection {
        case .plainFiles: ([file(plain), file(plain, "b/c.pdf")], links + [duplicate])
        case .encryptedFile: ([file(encrypted)], [duplicate, versions])
        case .readOnlyFile: ([file(readOnly)], links + [versions])
        case .serverFile: ([file(server)], [])
        case .fileAndFolder: ([file(plain), folder], [])
        case .twoDrives: ([file(plain), file(other)], [])
        case .outside: ([fixture.root.appending(path: "a.pdf")], [])
        case .nothing: ([], [])
        }

        #expect(app.reply(to: .menu(files)) == .menu(expected))
    }

    @Test func oneFolderOrADriveRootOffersRecentlyDeletedOnlyOnS3Drives() throws {
        let plain = Connection.s3(name: "Plain")
        let server = Connection.sftp(name: "Server")
        for connection in [plain, server] {
            try fixture.repository.save(connection, credentials: Credentials())
        }
        let app = fixture.app()
        func menu(_ connection: Connection, _ path: String) -> [FinderCommand] {
            guard case let .menu(items) = app.reply(to: .menu([fixture.paths.mount(connection).appending(path: path, directoryHint: .isDirectory)])) else { return [] }
            return items.map(\.command)
        }

        #expect(menu(plain, "b") == [.showRecentlyDeleted])
        #expect(menu(plain, "") == [.showRecentlyDeleted])
        #expect(menu(server, "b").isEmpty)
    }

    @Test func aCommandRunsTheSameWorkflowAsTheServicesEntry() async throws {
        let server = Connection.sftp()
        try fixture.repository.save(server, credentials: Credentials(password: "secret"))
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        let file = fixture.paths.mount(server).appending(path: "plan.pdf")

        #expect(app.reply(to: .run(.duplicateOnServer, files: [file])) == .accepted)
        let notification = await desktop.nextNotification()

        #expect(notification.title == String(localized: .couldNotDuplicate("plan.pdf")))
        #expect(notification.body.contains(server.provider.title))
    }

    @Test func aCopyLinkCommandExplainsWhyAnEncryptedDriveHasNoLinks() async throws {
        let encrypted = try fixture.saveEncryptedConnection()
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)

        #expect(app.reply(to: .run(.copyShareLink(.day), files: [fixture.paths.mount(encrypted).appending(path: "plan.pdf")])) == .accepted)
        let notification = await desktop.nextNotification()

        #expect(notification.title == String(localized: .couldNotCopyLink("plan.pdf")))
        #expect(notification.body == String(localized: .linksUnavailableEncrypted))
        #expect(desktop.copiedLinks.isEmpty)
    }
}

import Foundation
import Synchronization
import Testing
@testable import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite(.timeLimit(.minutes(1))) final class VersionsViewModelTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    private func serve(_ connection: Connection, versioning: String = "Enabled", queue: String = "") throws {
        let objects = ["report.txt", "report-v2026-11-02-140301-123.txt", "photo-v2026-11-01-100000-000.jpg"]
        try fixture.serve(connection) { request in
            switch request.method {
            case "backend/command": return #"{"result":"\#(versioning)"}"#
            case "operations/list", "operations/copyfile": return #"{"jobid":1}"#
            case "job/status":
                let items = objects.enumerated().map { #"{"Path":"\#($1)","Size":3,"ModTime":"2026-11-0\#($0 + 1)T10:00:00Z","IsDir":false}"# }
                return #"{"finished":true,"success":true,"error":"","output":{"list":[\#(items.joined(separator: ","))]}}"#
            case "vfs/queue": return #"{"queue":[\#(queue)]}"#
            default: return "{}"
            }
        }
    }

    private func show(_ name: String, in connection: Connection, desktop: TestDesktopServices) throws -> (AppViewModel, VersionsViewModel) {
        let app = fixture.app(desktop: desktop)
        app.showVersions(of: fixture.paths.mount(connection).appending(path: name))
        return try (app, #require(desktop.shownVersions.last))
    }

    @Test func aFileShowsItsCurrentVersionFirstAndOnlyOldVersionsCanBeRestored() async throws {
        let connection = Connection.s3()
        try serve(connection)
        let (_, versions) = try show("report.txt", in: connection, desktop: TestDesktopServices(paths: fixture.paths))
        await versions.load()
        #expect(versions.versions.map(\.path) == ["report.txt", "report-v2026-11-02-140301-123.txt"])
        #expect(versions.versions.map { versions.canRestore($0) } == [false, true])
        #expect(versions.title == String(localized: .versionsOf("report.txt")))
    }

    @Test func aFolderShowsItsDeletedFiles() async throws {
        let connection = Connection.s3()
        try serve(connection)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let (_, versions) = try show("", in: connection, desktop: desktop)
        await versions.load()
        #expect(versions.isFolder)
        #expect(versions.versions.map(\.filePath) == ["photo.jpg"])
        #expect(versions.title == String(localized: .recentlyDeletedIn(connection.name)))
    }

    @Test func aReadOnlyDriveShowsVersionsButCannotRestore() async throws {
        let connection = Connection.s3 { $0.readOnly = true }
        try serve(connection)
        let (_, versions) = try show("report.txt", in: connection, desktop: TestDesktopServices(paths: fixture.paths))
        await versions.load()
        #expect(versions.versions.count == 2)
        #expect(!versions.versions.contains { versions.canRestore($0) })
    }

    @Test(arguments: [("Suspended", true, 2), ("Unversioned", true, 0)])
    func pausedOrOffVersioningExplainsWhyAndUpdatesTheFinderMenu(state: String, notice: Bool, count: Int) async throws {
        let connection = Connection.s3()
        try serve(connection, versioning: state)
        let (app, versions) = try show("report.txt", in: connection, desktop: TestDesktopServices(paths: fixture.paths))
        await versions.load()
        #expect((versions.notice != nil) == notice)
        #expect(versions.versions.count == count)
        let menu = app.reply(to: .menu([fixture.paths.mount(connection).appending(path: "report.txt")]))
        #expect(menu.offersVersions == (state != "Unversioned"))
    }

    @Test func aRestoreOfAFileThatWaitsToUploadShowsWhyAndKeepsTheList() async throws {
        let connection = Connection.s3()
        try serve(connection, queue: #"{"name":"report.txt","id":1,"size":3,"expiry":1,"tries":0,"uploading":false}"#)
        let (_, versions) = try show("report.txt", in: connection, desktop: TestDesktopServices(paths: fixture.paths))
        await versions.load()
        versions.restore(versions.versions[1], asCopy: false)
        while versions.working != nil { try await Task.sleep(for: .milliseconds(20)) }
        #expect(versions.message == String(localized: .restoreFileStillUploading))
        #expect(versions.versions.count == 2)
        #expect(versions.working == nil)
    }

    @Test func anSFTPFileOpensNoVersionsWindow() throws {
        let connection = Connection.sftp()
        try fixture.repository.save(connection, credentials: Credentials())
        let desktop = TestDesktopServices(paths: fixture.paths)
        fixture.app(desktop: desktop).showVersions(of: fixture.paths.mount(connection).appending(path: "a.txt"))
        #expect(desktop.shownVersions.isEmpty)
    }
}

private extension FinderSyncReply {
    var offersVersions: Bool {
        guard case let .menu(items) = self else { return false }
        return items.contains { $0.command == .showVersions }
    }
}

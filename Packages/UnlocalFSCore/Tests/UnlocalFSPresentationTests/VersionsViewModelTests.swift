import Foundation
import Testing
@testable import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite(.timeLimit(.minutes(1))) final class VersionsViewModelTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    private func versions(of path: String, in connection: Connection, versioning: String = "Enabled", queue: String = "") throws
        -> (AppViewModel, VersionsViewModel) {
        let bucket = VersionedBucket(["report.txt", "report-v2026-11-02-140301-123.txt", "photo-v2026-11-01-100000-000.jpg"], queue: queue, versioning: versioning)
        try fixture.serve(connection, respond: bucket.respond)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        let mount = fixture.paths.mount(connection)
        app.showVersions(of: path.isEmpty ? mount.appending(path: "", directoryHint: .isDirectory) : mount.appending(path: path))
        return try (app, fixture.factory(app).makeVersions(#require(desktop.shownVersions.last)))
    }

    @Test func aFileShowsItsCurrentVersionFirstAndOnlyOldVersionsCanBeRestored() async throws {
        let (_, versions) = try versions(of: "report.txt", in: .s3())
        await versions.load()
        #expect(versions.versions.map(\.path) == ["report.txt", "report-v2026-11-02-140301-123.txt"])
        #expect(versions.versions.map { versions.canRestore($0) } == [false, true])
    }

    @Test func theDriveRootShowsItsDeletedFiles() async throws {
        let connection = Connection.s3()
        let (_, versions) = try versions(of: "", in: connection)
        await versions.load()
        #expect(versions.target.isFolder)
        #expect(versions.versions.map(\.filePath) == ["photo.jpg"])
        #expect(versions.title == String(localized: .recentlyDeletedIn(connection.name)))
    }

    @Test func aReadOnlyDriveShowsVersionsButCannotRestore() async throws {
        let (_, versions) = try versions(of: "report.txt", in: .s3 { $0.readOnly = true })
        await versions.load()
        #expect(versions.versions.count == 2)
        #expect(!versions.versions.contains { versions.canRestore($0) })
    }

    @Test(arguments: [("Suspended", 2), ("Unversioned", 0)])
    func pausedOrOffVersioningExplainsWhyAndUpdatesTheFinderMenu(state: String, count: Int) async throws {
        let connection = Connection.s3()
        let (app, versions) = try versions(of: "report.txt", in: connection, versioning: state)
        await versions.load()
        #expect(versions.notice != nil)
        #expect(versions.versions.count == count)
        let menu = app.reply(to: .menu([fixture.paths.mount(connection).appending(path: "report.txt")]))
        #expect(menu.offersVersions == (state != "Unversioned"))
    }

    @Test func aRefusedRestoreShowsTheReasonKeepsTheListAndEndsTheBusyState() async throws {
        let (_, versions) = try versions(of: "report.txt", in: .s3(), queue: "report.txt")
        await versions.load()
        versions.restore(versions.versions[1], asCopy: false)
        while versions.working != nil { try await Task.sleep(for: .milliseconds(20)) }
        #expect(versions.message == String(localized: .restoreFileStillUploading))
        #expect(versions.versions.count == 2)
    }
}

private extension FinderSyncReply {
    var offersVersions: Bool {
        guard case let .menu(items) = self else { return false }
        return items.contains { $0.command == .showVersions }
    }
}

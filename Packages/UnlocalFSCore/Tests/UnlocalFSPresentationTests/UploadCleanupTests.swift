import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

private let hour: TimeInterval = 3600
private let day = 24 * hour

@MainActor @Suite(.timeLimit(.minutes(1))) final class UploadCleanupTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func reviewCountsAbandonedAndRecentUploads() async throws {
        let connection = Connection.s3()
        let storage = try serve(connection, uploadAges: [2 * day, hour])
        let app = fixture.app()
        await app.refresh()

        await app.reviewUnfinishedUploads(connection)

        #expect(app.uploadCleanup == UploadCleanup(connection: connection, abandoned: 1, inFlight: 1))
        #expect(app.alert == nil)
        #expect(storage.commands == ["list-multipart-uploads"])
    }

    @Test func reviewWithOnlyRecentUploadsRemovesNothing() async throws {
        let connection = Connection.s3()
        let storage = try serve(connection, uploadAges: [hour])
        let app = fixture.app()
        await app.refresh()

        await app.reviewUnfinishedUploads(connection)

        #expect(app.uploadCleanup == nil)
        #expect(app.alert == "\(String(localized: .noAbandonedUploads(connection.name))) \(String(localized: .recentUploadsKept(1)))")
        #expect(storage.commands == ["list-multipart-uploads"])
    }

    @Test func cleanupKeepsTheDriveBusyAndReportsRemovedUploads() async throws {
        let connection = Connection.s3()
        let (entered, enter) = AsyncStream.makeStream(of: Void.self)
        let (release, resume) = AsyncStream.makeStream(of: Void.self)
        try serve(connection, uploadAges: [2 * day, hour]) { command in
            guard command == "cleanup" else { return }
            enter.yield()
            for await _ in release { break }
        }
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        await app.refresh()
        await app.reviewUnfinishedUploads(connection)
        let cleanup = try #require(app.uploadCleanup)

        let task = Task { await app.cleanUpUnfinishedUploads(cleanup) }
        for await _ in entered { break }
        #expect(!app.canToggle(connection))
        #expect(app.statusText(connection) == String(localized: .working))
        resume.yield()
        await task.value

        #expect(desktop.notifications.map(\.title) == [String(localized: .unfinishedUploadsRemoved(1))])
        #expect(app.alert == nil)
        #expect(app.canToggle(connection))
    }

    @Test func cleanupReportsUploadsThatRcloneCouldNotRemove() async throws {
        let connection = Connection.s3()
        try serve(connection, uploadAges: [2 * day], cleanupRemoves: false)
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        await app.refresh()

        await app.cleanUpUnfinishedUploads(UploadCleanup(connection: connection, abandoned: 1, inFlight: 0))

        #expect(app.alert == String(localized: .abandonedUploadsRemain(1)))
        #expect(desktop.notifications.isEmpty)
    }

    @Test func onlyRunningWritableDrivesCanCleanUp() async throws {
        let writable = Connection.s3(name: "Writable")
        let readOnly = Connection.s3(name: "Read-only") { $0.readOnly = true }
        let stopped = Connection.s3(name: "Stopped")
        for connection in [writable, readOnly] { try serve(connection, uploadAges: []) }
        try fixture.repository.save(stopped, credentials: .s3())
        let app = fixture.app()
        await app.refresh()

        #expect(app.canCleanUpUploads(writable))
        #expect(!app.canCleanUpUploads(readOnly))
        #expect(!app.canCleanUpUploads(stopped))
    }

    @discardableResult
    private func serve(
        _ connection: Connection, uploadAges: [TimeInterval], cleanupRemoves: Bool = true,
        onCommand: @escaping @Sendable (String) async -> Void = { _ in }
    ) throws -> FakeStorage {
        let storage = FakeStorage(uploadAges: uploadAges)
        try fixture.serve(connection) { request in
            switch request.method {
            case "backend/command":
                let command = request.parameter("command") ?? ""
                await onCommand(command)
                storage.run(command, removing: cleanupRemoves)
                return #"{"jobid":1}"#
            case "job/status":
                return #"{"finished":true,"success":true,"error":"","output":{"result":{"my-bucket":\#(storage.listing())}}}"#
            default:
                return #"{"results":[{"diskCache":{"uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0}},{"queue":[]},{\#(rcloneCounters)}]}"#
            }
        }
        return storage
    }
}

private final class FakeStorage: Sendable {
    private let uploadAges: Mutex<[TimeInterval]>
    private let received = Mutex<[String]>([])

    init(uploadAges: [TimeInterval]) { self.uploadAges = Mutex(uploadAges) }

    var commands: [String] { received.withLock { $0 } }

    func run(_ command: String, removing: Bool) {
        received.withLock { $0.append(command) }
        if command == "cleanup", removing { uploadAges.withLock { $0.removeAll { $0 > day } } }
    }

    func listing() -> String {
        let uploads = uploadAges.withLock { $0 }.enumerated().map { index, age in
            #"{"Key":"file-\#(index).bin","Initiated":"\#(Date.now.addingTimeInterval(-age).formatted(.iso8601))","UploadId":"\#(index)"}"#
        }
        return "[\(uploads.joined(separator: ","))]"
    }
}

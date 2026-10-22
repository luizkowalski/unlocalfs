import Foundation
import Synchronization
import Testing
@testable import UnlocalFSDomain
import UnlocalFSTestSupport
import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation

@MainActor @Suite(.timeLimit(.minutes(1))) final class AppPollingTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func healthyDriveUpdatesWhileAnotherDriveWaits() async throws {
        let slow = Connection.s3(name: "A slow")
        let fast = Connection.s3(name: "B fast")
        let (entered, enter) = AsyncStream.makeStream(of: Void.self)
        let (release, resume) = AsyncStream.makeStream(of: Void.self)
        defer { resume.finish() }
        try fixture.serve(slow) { _ in
            enter.finish()
            for await _ in release {}
            return Self.connected
        }
        try fixture.serve(fast) { _ in Self.connected }
        let app = fixture.app()
        let polling = Task { await app.refresh() }
        for await _ in entered {}

        for _ in 0..<100 where !app.isActive(fast) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(app.isActive(fast))
        #expect(!app.isActive(slow))
        resume.finish()
        await polling.value
        #expect(app.isActive(slow))
    }

    @Test func delayedStatusDoesNotRestoreADisconnectedDrive() async throws {
        let connection = Connection.s3()
        let socket = fixture.paths.socket(connection)
        let hold = Mutex(false)
        let (entered, enter) = AsyncStream.makeStream(of: Void.self)
        let (release, resume) = AsyncStream.makeStream(of: Void.self)
        defer { resume.finish() }
        try fixture.serve(connection) { request in
            switch request.method {
            case "job/list": return #"{"runningIds":[]}"#
            case "core/quit":
                try FileManager.default.removeItem(at: socket)
                return "{}"
            default:
                if hold.withLock({ held in
                    defer { held = false }
                    return held
                }) {
                    enter.finish()
                    for await _ in release {}
                }
                return Self.connected
            }
        }
        let app = fixture.app()
        await app.refresh()
        hold.withLock { $0 = true }
        let polling = Task { await app.refresh() }
        for await _ in entered {}

        await app.disconnect(connection)
        #expect(!app.isActive(connection))
        resume.finish()
        await polling.value

        #expect(!app.isActive(connection))
    }

    private nonisolated static let connected = #"{"results":[{"diskCache":{"uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0}},{"queue":[]},{\#(rcloneCounters)}]}"#

    @Test func loginItemStateIsNotReadOnEveryPoll() async throws {
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        desktop.opensAtLogin = true

        await app.refresh()

        #expect(!app.opensAtLogin)
        app.syncOpensAtLogin()
        #expect(app.opensAtLogin)
    }
}

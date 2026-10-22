import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite final class AppQuitTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func quitPromptBlocksDriveChangesUntilCancelled() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection, queued: 1)
        let app = fixture.app()
        await app.refresh()
        try #require(await app.quitDecision() == .disconnect)

        await app.disconnect(connection)

        #expect(app.uploadsBlockingDisconnect == nil)

        app.cancelQuit()
        await app.disconnect(connection)

        #expect(app.uploadsBlockingDisconnect == connection)
    }

    @Test func quitDisconnectsEveryDriveAtTheSameTime() async throws {
        let overlap = Overlap()
        for name in ["A drive", "B drive"] {
            let connection = Connection.s3(name: name)
            let socket = fixture.paths.socket(connection)
            try fixture.serve(connection) { request in
                switch request.method {
                case "job/list":
                    overlap.hold()
                    defer { overlap.release() }
                    try await Task.sleep(for: .milliseconds(200))
                    return #"{"runningIds":[]}"#
                case "core/quit":
                    try FileManager.default.removeItem(at: socket)
                    return "{}"
                default:
                    return #"{"results":[{"diskCache":{"uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0}},{"queue":[]},{\#(rcloneCounters)}]}"#
                }
            }
        }
        let app = fixture.app()
        await app.refresh()

        let failure = await app.disconnectForQuit()

        #expect(failure == nil)
        #expect(overlap.peak == 2)
    }

    @Test func quitTriesEveryDriveAndReportsTheFirstFailure() async throws {
        let blocked = Connection.s3(name: "A blocked drive")
        let connected = Connection.s3(name: "B connected drive")
        try fixture.serve(blocked, queued: 1)
        let socket = fixture.paths.socket(connected)
        try fixture.serve(connected) { request in
            if request.method == "job/list" { return #"{"runningIds":[]}"# }
            if request.method == "core/quit" {
                try FileManager.default.removeItem(at: socket)
                return "{}"
            }
            return #"{"results":[{"diskCache":{"uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0}},{"queue":[]},{\#(rcloneCounters)}]}"#
        }
        let app = fixture.app()
        await app.refresh()
        let status = await fixture.service.status(connected)
        try #require(status.isRunning && status.controlError == nil)

        let failure = await app.disconnectForQuit()

        #expect(await fixture.service.status(blocked).isActive)
        #expect(await !fixture.service.status(connected).isActive)
        #expect(app.uploadsBlockingDisconnect == nil)
        #expect(failure?.connection == blocked)
        #expect(failure?.error is UploadsPendingError)
        #expect(!app.isActive(connected))
    }
}

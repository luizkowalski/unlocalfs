import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite struct AppQuitTests {
    @Test func quitPromptBlocksDriveChangesUntilCancelled() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
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

    @Test func quitTriesEveryDriveAndReportsTheFirstFailure() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
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
            return #"{"results":[{"diskCache":{"uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0}},{"queue":[]},{}]}"#
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

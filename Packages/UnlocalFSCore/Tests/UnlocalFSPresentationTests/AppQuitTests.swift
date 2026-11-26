import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor final class AppQuitTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func quitPromptBlocksDriveChangesUntilCancelled() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection, queued: 1)
        let app = fixture.app()
        await app.refresh()
        try #require(await app.quitDecision() == .disconnect([connection]))

        await app.disconnect(connection)

        #expect(app.uploadsBlockingDisconnect == nil)

        app.cancelQuit()
        await app.disconnect(connection)

        #expect(app.uploadsBlockingDisconnect == connection)
    }

    @Test func quitDisconnectsEveryActiveDriveAtTheSameTimeWithoutAStatusPass() async throws {
        let overlap = Overlap()
        for name in ["A drive", "B drive"] {
            try fixture.serveRunning(Connection.s3(name: name)) {
                overlap.hold()
                defer { overlap.release() }
                try await Task.sleep(for: .milliseconds(200))
            }
        }
        let app = fixture.app()
        try #require(await app.quitDecision() == .disconnect(app.connections))

        let failure = await app.disconnectForQuit(app.connections)

        #expect(failure == nil)
        #expect(overlap.peak == 2)
        for connection in app.connections {
            #expect(await !fixture.service.status(connection).isRunning)
        }
    }

    @Test func quitTriesEveryDriveAndReportsTheFirstFailure() async throws {
        let blocked = Connection.s3(name: "A blocked drive")
        let connected = Connection.s3(name: "B connected drive")
        try fixture.serve(blocked, queued: 1)
        try fixture.serveRunning(connected)
        let app = fixture.app()
        await app.refresh()
        let status = await fixture.service.status(connected)
        try #require(status.isRunning && status.controlError == nil)
        try #require(await app.quitDecision() == .disconnect([blocked, connected]))

        let failure = await app.disconnectForQuit([blocked, connected])

        #expect(await fixture.service.status(blocked).isActive)
        #expect(await !fixture.service.status(connected).isActive)
        #expect(app.uploadsBlockingDisconnect == nil)
        #expect(failure?.connection == blocked)
        #expect(failure?.error is UploadsPendingError)
        #expect(!app.isActive(connected))
    }
}

import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite final class ActivityViewModelTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func activityRecoversAfterTheControlServiceReturns() async throws {
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false }, recordSpeed: { _, _ in })
        let connection = Connection.s3()
        try fixture.serve(connection)
        try Data("unavailable".utf8).write(to: fixture.root.appending(path: "queue.json"))

        await viewModel.refresh(connection)
        guard case .failure = viewModel.activity else {
            Issue.record("Expected unavailable activity")
            return
        }

        try fixture.queue(#"{"name":"photo.jpg","id":1,"size":2048,"expiry":4,"tries":0,"delay":5,"uploading":false}"#)
        await viewModel.refresh(connection)

        let activity = try #require(viewModel.activity).get()
        #expect(activity.map(\.path) == ["photo.jpg"])
    }

    @Test func busyConnectionsWaitBeforeLoadingActivity() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection)
        var busy = true
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in busy }, recordSpeed: { _, _ in })

        await viewModel.refresh(connection)
        #expect(viewModel.activity == nil)

        busy = false
        await viewModel.refresh(connection)
        #expect(try #require(viewModel.activity).get().isEmpty)
    }

    @Test func activityPollsFastOnlyWhileTransfersAreActive() async throws {
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false }, recordSpeed: { _, _ in })
        let connection = Connection.s3()
        try fixture.serve(connection)

        await viewModel.refresh(connection)
        #expect(viewModel.refreshInterval == .seconds(2))

        try fixture.queue(#"{"name":"photo.jpg","id":1,"size":2048,"expiry":4,"tries":0,"delay":5,"uploading":false}"#)
        await viewModel.refresh(connection)
        #expect(viewModel.refreshInterval == .milliseconds(500))

        try fixture.queue(#"{"name":"photo.jpg","id":1,"size":2048,"expiry":4,"tries":1,"delay":5,"uploading":false}"#)
        await viewModel.refresh(connection)
        #expect(viewModel.refreshInterval == .seconds(2))
    }

    @Test func openDrivePageUpdatesTheSpeedHistoryLive() async throws {
        let connection = Connection.s3()
        try fixture.serve(connection)
        let app = fixture.app()
        let viewModel = fixture.factory(app).makeActivity()
        await app.refresh()

        try transferring(speed: 700)
        await viewModel.refresh(connection)

        #expect(app.speeds[connection.id]?.last?.download == 700)
    }

    @Test func cancelledRefreshDoesNotReplaceTheNextDrivesActivity() async throws {
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false }, recordSpeed: { _, _ in })
        let previous = Connection.s3(name: "Previous")
        let current = Connection.s3()
        try fixture.serve(previous) { _ in
            try await Task.sleep(for: .milliseconds(300))
            throw ControlFailure("Previous drive failed")
        }
        try fixture.serve(current)

        let refreshingPrevious = Task { await viewModel.refresh(previous) }
        refreshingPrevious.cancel()
        await viewModel.refresh(current)
        await refreshingPrevious.value

        #expect(try #require(viewModel.activity).get().isEmpty)
    }

    @Test func cancelledObservationStopsWithoutLoadingActivity() async throws {
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false }, recordSpeed: { _, _ in })
        let task = Task { await viewModel.observe(Connection.s3()) }
        task.cancel()

        await task.value

        #expect(viewModel.activity == nil)
    }

    private func transferring(speed: Int) throws {
        try Data(#"{\#(rcloneCounters),"transferring":[{"name":"c.mov","size":1000,"bytes":100,"speedAvg":\#(speed),"srcFs":":s3:bucket"}]}"#.utf8)
            .write(to: fixture.root.appending(path: "stats.json"))
    }
}

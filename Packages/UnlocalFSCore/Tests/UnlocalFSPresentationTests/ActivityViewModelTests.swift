import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite struct ActivityViewModelTests {
    @Test func activityRecoversAfterTheControlServiceReturns() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false })
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
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = Connection.s3()
        try fixture.serve(connection)
        var busy = true
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in busy })

        await viewModel.refresh(connection)
        #expect(viewModel.activity == nil)

        busy = false
        await viewModel.refresh(connection)
        #expect(try #require(viewModel.activity).get().isEmpty)
    }

    @Test func activityRefreshesFourTimesASecondWhileFilesShow() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false })
        let connection = Connection.s3()
        try fixture.serve(connection)

        await viewModel.refresh(connection)
        #expect(viewModel.refreshInterval == .seconds(1))

        try fixture.queue(#"{"name":"photo.jpg","id":1,"size":2048,"expiry":4,"tries":0,"delay":5,"uploading":false}"#)
        await viewModel.refresh(connection)
        #expect(viewModel.refreshInterval == .milliseconds(250))
    }

    @Test func cancelledRefreshDoesNotReplaceTheNextDrivesActivity() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false })
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
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false })
        let task = Task { await viewModel.observe(Connection.s3()) }
        task.cancel()

        await task.value

        #expect(viewModel.activity == nil)
    }
}

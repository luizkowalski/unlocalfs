import Foundation
import Testing
@testable import UnlocalFSPresentation

@MainActor @Suite struct ActivityViewModelTests {
    @Test func activityRecoversAfterTheControlServiceReturns() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false })
        let connection = connectionFixture()
        try Data("unavailable".utf8).write(to: fixture.root.appending(path: "queue.json"))

        await viewModel.refresh(connection)
        guard case .failure = viewModel.activity else {
            Issue.record("Expected unavailable activity")
            return
        }

        try Data(#"{"queue":[{"name":"photo.jpg","id":1,"size":2048,"expiry":4,"tries":0,"delay":5,"uploading":false}]}"#.utf8)
            .write(to: fixture.root.appending(path: "queue.json"))
        await viewModel.refresh(connection)

        let activity = try #require(viewModel.activity).get()
        #expect(activity.map(\.path) == ["photo.jpg"])
    }

    @Test func busyConnectionsWaitBeforeLoadingActivity() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        var busy = true
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in busy })

        await viewModel.refresh(connection)
        #expect(viewModel.activity == nil)

        busy = false
        await viewModel.refresh(connection)
        #expect(try #require(viewModel.activity).get().isEmpty)
    }

    @Test func cancelledObservationStopsWithoutLoadingActivity() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let viewModel = ActivityViewModel(drives: fixture.service, isBusy: { _ in false })
        let task = Task { await viewModel.observe(connectionFixture()) }
        task.cancel()

        await task.value

        #expect(viewModel.activity == nil)
    }
}

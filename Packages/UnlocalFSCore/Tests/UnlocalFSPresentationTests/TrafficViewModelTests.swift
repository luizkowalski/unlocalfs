import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite(.timeLimit(.minutes(1))) final class TrafficViewModelTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func monthListsEverySavedDriveByTotalWithTheAllDrivesTotal() throws {
        let photos = Connection.s3 { $0.name = "Photos" }
        let server = Connection.sftp { $0.name = "Server" }
        try fixture.repository.save(server, credentials: Credentials())
        try fixture.repository.save(photos, credentials: Credentials())
        try record(Traffic(upload: 20_000, download: 10_000), for: photos, on: .now)
        let traffic = fixture.factory(fixture.app()).makeTraffic()

        traffic.reload()

        #expect(traffic.period == .month)
        #expect(traffic.rows == [
            DriveTraffic(id: photos.id, name: "Photos", provider: photos.provider, traffic: Traffic(upload: 20_000, download: 10_000)),
            DriveTraffic(id: server.id, name: "Server", provider: server.provider, traffic: Traffic()),
        ])
        #expect(traffic.total == Traffic(upload: 20_000, download: 10_000))
        #expect(traffic.error == nil)
    }

    @Test func deletedDriveShowsOnlyInRangesWhereItHasTraffic() throws {
        let deleted = Connection.s3 { $0.name = "Old Bucket" }
        try record(Traffic(upload: 0, download: 1_000), for: deleted, on: yesterday)
        let traffic = fixture.factory(fixture.app()).makeTraffic()

        traffic.period = .today
        #expect(traffic.rows.isEmpty)
        traffic.period = .custom
        traffic.end = yesterday
        traffic.start = yesterday - 4 * 86_400
        #expect(traffic.rows.map(\.name) == ["Old Bucket"])
        #expect(traffic.total == Traffic(upload: 0, download: 1_000))
    }

    @Test func unsavedBytesOfARunningDriveCountOnlyForRangesWithToday() async throws {
        let connection = Connection.s3 { $0.name = "Live" }
        try fixture.serve(connection, downloaded: 5_000)
        let app = fixture.app()
        await app.refresh()
        let traffic = fixture.factory(app).makeTraffic()

        traffic.period = .today
        #expect(traffic.rows.map(\.traffic) == [Traffic(upload: 0, download: 5_000)])
        traffic.period = .custom
        traffic.end = yesterday
        #expect(traffic.rows.map(\.traffic) == [Traffic()])
    }

    @Test func customRangeStaysInThePastAndInOrder() {
        let traffic = fixture.factory(fixture.app()).makeTraffic()

        traffic.end = .distantFuture
        #expect(traffic.end <= .now)
        traffic.start = .distantFuture
        #expect(traffic.start == traffic.end)
        traffic.end = .distantPast
        #expect(traffic.start == .distantPast)
    }

    @Test func failedQueryShowsTheErrorAndNoNumbers() {
        let broken = TrafficStore(url: URL(filePath: "/dev/null/traffic.sqlite"))
        let traffic = TrafficViewModel(repository: broken, connections: { [Connection.s3()] }, unsaved: { [:] })

        traffic.reload()

        #expect(traffic.rows.isEmpty)
        #expect(traffic.total == nil)
        #expect(traffic.error != nil)
    }

    private var yesterday: Date { Calendar.current.date(byAdding: .day, value: -1, to: .now)! }

    private func record(_ traffic: Traffic, for connection: Connection, on date: Date) throws {
        let checkpoint = TrafficCheckpoint(process: RcloneProcess(pid: 1, startedAt: .distantPast), network: 0, uploaded: 0, savedAt: date)
        try fixture.traffic.save(TrafficSave(day: TrafficDay(date, calendar: .current), traffic: traffic, checkpoint: checkpoint), for: connection)
    }
}

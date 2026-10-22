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

    @Test func last30DaysListsDrivesWithTrafficByTotalAndNamesTheQuietOnes() throws {
        let archive = Connection.s3 { $0.name = "Archive" }
        let photos = Connection.s3 { $0.name = "Photos" }
        let server = Connection.sftp { $0.name = "Server" }
        for connection in [archive, photos, server] { try fixture.repository.save(connection, credentials: Credentials()) }
        try record(Traffic(upload: 1_000, download: 0), for: photos, on: .now)
        try record(Traffic(upload: 20_000, download: 10_000), for: server, on: yesterday)
        let traffic = fixture.factory(fixture.app()).makeTraffic()

        traffic.reload()

        #expect(traffic.period == .last30Days)
        #expect(traffic.rows == [
            DriveTraffic(id: server.id, name: "Server", provider: server.provider, traffic: Traffic(upload: 20_000, download: 10_000)),
            DriveTraffic(id: photos.id, name: "Photos", provider: photos.provider, traffic: Traffic(upload: 1_000, download: 0)),
        ])
        #expect(traffic.quiet == ["Archive"])
        #expect(traffic.total == Traffic(upload: 21_000, download: 10_000))
        #expect(traffic.bars.suffix(2).map(\.traffic) == [Traffic(upload: 20_000, download: 10_000), Traffic(upload: 1_000, download: 0)])
        #expect(traffic.bars.count == 30)
        #expect(traffic.recentTotal == Traffic(upload: 21_000, download: 10_000))
        #expect(traffic.error == nil)
    }

    @Test func twelveMonthsShowsABarPerMonth() throws {
        let photos = Connection.s3 { $0.name = "Photos" }
        try record(Traffic(upload: 0, download: 1_000), for: photos, on: .now)
        try record(Traffic(upload: 0, download: 500), for: photos, on: Calendar.current.date(byAdding: .month, value: -3, to: .now)!)
        let traffic = fixture.factory(fixture.app()).makeTraffic()

        traffic.period = .last12Months

        #expect(traffic.unit == .month)
        #expect(traffic.bars.map(\.traffic.download) == Array(repeating: 0, count: 8) + [500, 0, 0, 1_000])
        #expect(traffic.total == Traffic(upload: 0, download: 1_500))
    }

    @Test func pickedDaysLimitTheTotalsUntilThePeriodChanges() throws {
        let photos = Connection.s3 { $0.name = "Photos" }
        try record(Traffic(upload: 0, download: 1_000), for: photos, on: yesterday)
        try record(Traffic(upload: 50, download: 0), for: photos, on: .now)
        let traffic = fixture.factory(fixture.app()).makeTraffic()
        traffic.reload()

        traffic.pick(yesterday...yesterday)

        #expect(traffic.picked == DateInterval(start: Calendar.current.startOfDay(for: yesterday), end: Calendar.current.startOfDay(for: .now)))
        #expect(traffic.total == Traffic(upload: 0, download: 1_000))
        #expect(traffic.bars.filter(traffic.highlights).map(\.interval.start) == [Calendar.current.startOfDay(for: yesterday)])
        traffic.period = .last90Days
        #expect(traffic.picked == nil)
        #expect(traffic.total == Traffic(upload: 50, download: 1_000))
    }

    @Test func deletedDriveShowsOnlyInRangesWhereItHasTraffic() throws {
        let deleted = Connection.s3 { $0.name = "Old Bucket" }
        try record(Traffic(upload: 0, download: 1_000), for: deleted, on: yesterday)
        let traffic = fixture.factory(fixture.app()).makeTraffic()

        showCustom(Date.now...Date.now, in: traffic)
        #expect(traffic.rows.isEmpty && traffic.quiet.isEmpty)
        showCustom(yesterday - 4 * 86_400...yesterday, in: traffic)
        #expect(traffic.rows.map(\.name) == ["Old Bucket"])
        #expect(traffic.total == Traffic(upload: 0, download: 1_000))
    }

    @Test func unsavedBytesOfARunningDriveCountOnlyForRangesWithToday() async throws {
        let connection = Connection.s3 { $0.name = "Live" }
        try fixture.serve(connection, downloaded: 5_000)
        let app = fixture.app()
        await app.refresh()
        let traffic = fixture.factory(app).makeTraffic()

        traffic.reload()
        #expect(traffic.rows.map(\.traffic) == [Traffic(upload: 0, download: 5_000)])
        #expect(traffic.bars.last?.traffic == Traffic(upload: 0, download: 5_000))
        showCustom(yesterday...yesterday, in: traffic)
        #expect(traffic.rows.isEmpty)
        #expect(traffic.quiet == ["Live"])
        #expect(traffic.bars.map(\.traffic) == [Traffic()])
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

    private func showCustom(_ range: ClosedRange<Date>, in traffic: TrafficViewModel) {
        traffic.period = .custom
        traffic.custom = range
    }

    private func record(_ traffic: Traffic, for connection: Connection, on date: Date) throws {
        let checkpoint = TrafficCheckpoint(process: RcloneProcess(pid: 1, startedAt: .distantPast), network: 0, savedAt: date)
        try fixture.traffic.save(TrafficSave(day: TrafficDay(date, calendar: .current), traffic: traffic, checkpoint: checkpoint), for: connection)
    }
}

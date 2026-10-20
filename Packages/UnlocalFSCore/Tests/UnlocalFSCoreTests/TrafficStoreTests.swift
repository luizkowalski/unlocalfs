import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure

@Suite struct TrafficStoreTests {
    private let file = URL.temporaryDirectory.appending(path: "traffic-\(UUID().uuidString).sqlite")
    private let rclone = RcloneProcess(pid: 42, startedAt: Date(timeIntervalSince1970: 1_000.123456))
    private let drive = Connection.s3 { $0.name = "Photos" }

    @Test func savesOnTheSameDayAddUpAndRangesSumPerDrive() throws {
        defer { try? FileManager.default.removeItem(at: file) }
        let store = TrafficStore(url: file)
        let other = Connection.sftp { $0.name = "Server" }
        try store.save(save("2026-10-18", upload: 1, download: 2), for: drive)
        try store.save(save("2026-10-19", upload: 10, download: 20), for: drive)
        try store.save(save("2026-10-19", upload: 100, download: 200), for: drive)
        try store.save(save("2026-10-20", upload: 1_000, download: 2_000), for: drive)
        try store.save(save("2026-10-19", upload: 5, download: 0), for: other)

        let traffic = try store.traffic(from: TrafficDay(rawValue: "2026-10-19"), through: TrafficDay(rawValue: "2026-10-19"))

        #expect(Set(traffic.map(\.id)) == [drive.id, other.id])
        #expect(traffic.first { $0.id == drive.id } == DriveTraffic(id: drive.id, name: "Photos", provider: drive.provider, traffic: Traffic(upload: 110, download: 220)))
        #expect(traffic.first { $0.id == other.id }?.traffic == Traffic(upload: 5, download: 0))
    }

    @Test func driveKeepsItsLatestNameAndShowsOnlyInRangesWithTraffic() throws {
        defer { try? FileManager.default.removeItem(at: file) }
        let store = TrafficStore(url: file)
        try store.save(save("2026-10-18", upload: 1, download: 0), for: drive)
        var renamed = drive
        renamed.name = "Holiday Photos"
        try store.save(save("2026-10-19", upload: 0, download: 5), for: renamed)

        #expect(try store.traffic(from: TrafficDay(rawValue: "2026-10-01"), through: TrafficDay(rawValue: "2026-10-31")).map(\.name) == ["Holiday Photos"])
        #expect(try store.traffic(from: TrafficDay(rawValue: "2026-10-20"), through: TrafficDay(rawValue: "2026-10-31")).isEmpty)
    }

    @Test func checkpointSurvivesReopeningTheFile() throws {
        defer { try? FileManager.default.removeItem(at: file) }
        #expect(try TrafficStore(url: file).checkpoint(for: drive.id) == nil)
        let saved = save("2026-10-19", upload: 1, download: 2)
        try TrafficStore(url: file).save(saved, for: drive)

        #expect(try TrafficStore(url: file).checkpoint(for: drive.id) == saved.checkpoint)
    }

    private func save(_ day: String, upload: Int64, download: Int64) -> TrafficSave {
        let checkpoint = TrafficCheckpoint(process: rclone, network: 5_000, uploaded: 2_000, savedAt: Date(timeIntervalSince1970: 1_760_000_000.5))
        return TrafficSave(day: TrafficDay(rawValue: day), traffic: Traffic(upload: upload, download: download), checkpoint: checkpoint)
    }
}

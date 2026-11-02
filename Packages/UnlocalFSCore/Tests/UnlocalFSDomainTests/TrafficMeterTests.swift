import Foundation
import Testing
import UnlocalFSDomain

struct TrafficMeterTests {
    private let rclone = RcloneProcess(pid: 42, startedAt: Date(timeIntervalSince1970: 1000))
    private let noon = utc.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 12))!

    @Test func firstReadingWithoutCheckpointCountsEverythingAndStartsTheHour() {
        var meter = TrafficMeter(checkpoint: nil)
        #expect(meter.read(reading(network: 10000, uploaded: 4000), calendar: utc) == nil)
        #expect(meter.unsaved == Traffic(upload: 4000, download: 6000))
        #expect(meter.read(reading(network: 11000, uploaded: 4000, at: noon + 3599), calendar: utc) == nil)
    }

    @Test func resumedProcessCountsTheGapAsDownloadAndLaterUploadsAsUpload() {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 50000))
        _ = meter.read(reading(network: 60000, uploaded: 24000), calendar: utc)
        #expect(meter.unsaved == Traffic(upload: 0, download: 10000))
        _ = meter.read(reading(network: 70000, uploaded: 28000), calendar: utc)
        #expect(meter.unsaved == Traffic(upload: 4000, download: 16000))
    }

    @Test func newProcessCountsFromZero() {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 50000))
        let restarted = RcloneProcess(pid: 43, startedAt: Date(timeIntervalSince1970: 9000))
        _ = meter.read(reading(network: 3000, uploaded: 1000, process: restarted), calendar: utc)
        #expect(meter.unsaved == Traffic(upload: 1000, download: 2000))
    }

    @Test func rcloneRestartSavesWhatTheOldProcessMoved() throws {
        var meter = TrafficMeter(checkpoint: nil)
        _ = meter.read(reading(network: 3000, uploaded: 1000), calendar: utc)
        let restarted = RcloneProcess(pid: 43, startedAt: Date(timeIntervalSince1970: 9000))
        let due = meter.read(reading(network: 500, uploaded: 0, process: restarted, at: noon + 60), calendar: utc)
        let save = try #require(due)
        #expect(save.traffic == Traffic(upload: 1000, download: 2000))
        #expect(meter.unsaved == Traffic(upload: 0, download: 500))
    }

    @Test func staleReadingWithALowerTotalAddsNothing() {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 50000))
        _ = meter.read(reading(network: 40000, uploaded: 10000), calendar: utc)
        #expect(meter.unsaved == Traffic())
        #expect(meter.save(calendar: utc) == nil)
    }

    @Test func uploadsNeverExceedTheNetworkBytes() {
        var meter = TrafficMeter(checkpoint: nil)
        _ = meter.read(reading(network: 1000, uploaded: 5000), calendar: utc)
        #expect(meter.unsaved == Traffic(upload: 1000, download: 0))
    }

    @Test func newDaySavesThePreviousDayUpToTheLastReading() throws {
        let beforeMidnight = try #require(utc.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 23, minute: 59, second: 58)))
        var meter = TrafficMeter(checkpoint: checkpoint(network: 0, savedAt: beforeMidnight - 1800))
        _ = meter.read(reading(network: 1000, uploaded: 0, at: beforeMidnight), calendar: utc)
        let due = meter.read(reading(network: 2000, uploaded: 0, at: beforeMidnight + 3), calendar: utc)
        let save = try #require(due)
        #expect(save.day == TrafficDay(rawValue: "2026-10-19"))
        #expect(save.traffic == Traffic(upload: 0, download: 1000))
        #expect(meter.unsaved == Traffic(upload: 0, download: 1000))
        let nextDue = meter.save(calendar: utc)
        let next = try #require(nextDue)
        #expect(next.day == TrafficDay(rawValue: "2026-10-20"))
        #expect(next.traffic == Traffic(upload: 0, download: 1000))
    }

    @Test func saveIsDueAfterAnHour() throws {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 0, savedAt: noon))
        #expect(meter.read(reading(network: 1000, uploaded: 0, at: noon + 3599), calendar: utc) == nil)
        let due = meter.read(reading(network: 3000, uploaded: 1000, at: noon + 3600), calendar: utc)
        let save = try #require(due)
        #expect(save.traffic == Traffic(upload: 1000, download: 2000))
        #expect(save.checkpoint == TrafficCheckpoint(process: rclone, network: 3000, savedAt: noon + 3600))
        #expect(meter.unsaved == Traffic())
        #expect(meter.read(reading(network: 4000, uploaded: 1000, at: noon + 3700), calendar: utc) == nil)
    }

    @Test func idleHourWritesNothing() {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 1000, savedAt: noon))
        #expect(meter.read(reading(network: 1000, uploaded: 0, at: noon + 3600), calendar: utc) == nil)
    }

    private func reading(network: Int64, uploaded: Int64, process: RcloneProcess? = nil, at date: Date? = nil) -> TrafficReading {
        TrafficReading(process: process ?? rclone, network: network, uploaded: uploaded, date: date ?? noon)
    }

    private func checkpoint(network: Int64, savedAt: Date? = nil) -> TrafficCheckpoint {
        TrafficCheckpoint(process: rclone, network: network, savedAt: savedAt ?? noon - 600)
    }
}

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

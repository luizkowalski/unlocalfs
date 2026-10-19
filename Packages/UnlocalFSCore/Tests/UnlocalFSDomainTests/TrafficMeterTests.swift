import Foundation
import Testing
import UnlocalFSDomain

@Suite struct TrafficMeterTests {
    private let rclone = RcloneProcess(pid: 42, startedAt: Date(timeIntervalSince1970: 1_000))
    private let noon = utc.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 12))!

    @Test func firstReadingWithoutCheckpointCountsEverything() {
        var meter = TrafficMeter(checkpoint: nil)
        #expect(meter.read(reading(network: 10_000, uploaded: 4_000), calendar: utc) == nil)
        #expect(meter.unsaved == Traffic(upload: 4_000, download: 6_000))
    }

    @Test func sameProcessCountsOnlyWhatMovedSinceTheCheckpoint() {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 50_000, uploaded: 20_000))
        _ = meter.read(reading(network: 60_000, uploaded: 24_000), calendar: utc)
        #expect(meter.unsaved == Traffic(upload: 4_000, download: 6_000))
    }

    @Test func newProcessCountsFromZero() {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 50_000, uploaded: 20_000))
        let restarted = RcloneProcess(pid: 43, startedAt: Date(timeIntervalSince1970: 9_000))
        _ = meter.read(reading(network: 3_000, uploaded: 1_000, process: restarted), calendar: utc)
        #expect(meter.unsaved == Traffic(upload: 1_000, download: 2_000))
    }

    @Test func readingAfterSleepCountsOnlyWhatMovedSinceTheCheckpoint() {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 10_000, uploaded: 0, savedAt: noon))
        let save = meter.read(reading(network: 12_000, uploaded: 0, at: noon + 8 * 3_600), calendar: utc)
        #expect(save?.traffic == Traffic(upload: 0, download: 2_000))
    }

    @Test func staleReadingWithALowerTotalAddsNothing() {
        let saved = checkpoint(network: 50_000, uploaded: 20_000)
        var meter = TrafficMeter(checkpoint: saved)
        _ = meter.read(reading(network: 40_000, uploaded: 10_000), calendar: utc)
        #expect(meter.unsaved == Traffic())
        #expect(meter.save(calendar: utc) == nil)
        #expect(meter.checkpoint == saved)
    }

    @Test func uploadsNeverExceedTheNetworkBytes() {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 50_000, uploaded: 20_000))
        _ = meter.read(reading(network: 51_000, uploaded: 25_000), calendar: utc)
        #expect(meter.unsaved == Traffic(upload: 1_000, download: 0))
    }

    @Test func uploadsSeenBelowTheCheckpointCountAsDownloads() {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 50_000, uploaded: 20_000))
        _ = meter.read(reading(network: 53_000, uploaded: 2_000), calendar: utc)
        #expect(meter.unsaved == Traffic(upload: 0, download: 3_000))
    }

    @Test func newDaySavesThePreviousDayUpToTheLastReading() throws {
        let beforeMidnight = utc.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 23, minute: 59, second: 58))!
        var meter = TrafficMeter(checkpoint: checkpoint(network: 0, uploaded: 0, savedAt: beforeMidnight - 1_800))
        _ = meter.read(reading(network: 1_000, uploaded: 0, at: beforeMidnight), calendar: utc)
        let due = meter.read(reading(network: 2_000, uploaded: 0, at: beforeMidnight + 3), calendar: utc)
        let save = try #require(due)
        #expect(save.day == TrafficDay(rawValue: "2026-10-19"))
        #expect(save.traffic == Traffic(upload: 0, download: 1_000))
        #expect(meter.unsaved == Traffic(upload: 0, download: 1_000))
        let nextDue = meter.save(calendar: utc)
        let next = try #require(nextDue)
        #expect(next.day == TrafficDay(rawValue: "2026-10-20"))
        #expect(next.traffic == Traffic(upload: 0, download: 1_000))
    }

    @Test func saveIsDueAfterAnHour() throws {
        var meter = TrafficMeter(checkpoint: checkpoint(network: 0, uploaded: 0, savedAt: noon))
        #expect(meter.read(reading(network: 1_000, uploaded: 0, at: noon + 3_599), calendar: utc) == nil)
        let due = meter.read(reading(network: 3_000, uploaded: 1_000, at: noon + 3_600), calendar: utc)
        let save = try #require(due)
        #expect(save.traffic == Traffic(upload: 1_000, download: 2_000))
        #expect(save.checkpoint == TrafficCheckpoint(process: rclone, network: 3_000, uploaded: 1_000, savedAt: noon + 3_600))
        #expect(meter.unsaved == Traffic())
        #expect(meter.read(reading(network: 4_000, uploaded: 1_000, at: noon + 3_700), calendar: utc) == nil)
    }

    @Test func idleHourWritesNothing() {
        let saved = checkpoint(network: 1_000, uploaded: 0, savedAt: noon)
        var meter = TrafficMeter(checkpoint: saved)
        #expect(meter.read(reading(network: 1_000, uploaded: 0, at: noon + 3_600), calendar: utc) == nil)
        #expect(meter.checkpoint == saved)
    }

    @Test func firstReadingStartsTheHourWhenNothingWasSaved() {
        var meter = TrafficMeter(checkpoint: nil)
        #expect(meter.read(reading(network: 1_000, uploaded: 0, at: noon), calendar: utc) == nil)
        #expect(meter.read(reading(network: 2_000, uploaded: 0, at: noon + 3_599), calendar: utc) == nil)
    }

    @Test func savingOnDemandMovesTheCheckpoint() throws {
        var meter = TrafficMeter(checkpoint: nil)
        #expect(meter.save(calendar: utc) == nil)
        _ = meter.read(reading(network: 5_000, uploaded: 2_000), calendar: utc)
        let due = meter.save(calendar: utc)
        let save = try #require(due)
        #expect(save.day == TrafficDay(rawValue: "2026-10-19"))
        #expect(save.traffic == Traffic(upload: 2_000, download: 3_000))
        #expect(meter.unsaved == Traffic())
    }

    private func reading(network: Int64, uploaded: Int64, process: RcloneProcess? = nil, at date: Date? = nil) -> TrafficReading {
        TrafficReading(process: process ?? rclone, network: network, uploaded: uploaded, date: date ?? noon)
    }

    private func checkpoint(network: Int64, uploaded: Int64, savedAt: Date? = nil) -> TrafficCheckpoint {
        TrafficCheckpoint(process: rclone, network: network, uploaded: uploaded, savedAt: savedAt ?? noon - 600)
    }
}

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

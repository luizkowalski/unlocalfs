import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSPresentation

@Suite struct TrafficPeriodTests {
    private let wednesday = date(2026, 10, 21, hour: 15)

    @Test(arguments: [
        (TrafficPeriod.last30Days, date(2026, 9, 22), date(2026, 10, 22)),
        (.last90Days, date(2026, 7, 24), date(2026, 10, 22)),
        (.last12Months, date(2025, 11, 1), date(2026, 10, 22)),
        (.custom, date(2026, 9, 30), date(2026, 10, 3)),
    ])
    func periodCoversWholeDays(period: TrafficPeriod, start: Date, end: Date) {
        let custom = date(2026, 9, 30, hour: 23)...date(2026, 10, 2, hour: 8)
        #expect(period.interval(now: wednesday, custom: custom, calendar: utc) == DateInterval(start: start, end: end))
    }

    @Test(arguments: [
        (TrafficPreset.today, date(2026, 10, 21), date(2026, 10, 21)),
        (.yesterday, date(2026, 10, 20), date(2026, 10, 20)),
        (.last7Days, date(2026, 10, 15), date(2026, 10, 21)),
        (.thisMonth, date(2026, 10, 1), date(2026, 10, 21)),
        (.lastMonth, date(2026, 9, 1), date(2026, 9, 30)),
        (.thisYear, date(2026, 1, 1), date(2026, 10, 21)),
    ])
    func presetPicksItsCalendarDays(preset: TrafficPreset, first: Date, last: Date) {
        #expect(preset.days(now: wednesday, calendar: utc) == first...last)
    }
}

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

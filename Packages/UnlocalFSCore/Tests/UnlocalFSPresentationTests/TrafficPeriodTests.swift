import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSPresentation

@Suite struct TrafficPeriodTests {
    private let wednesday = utc.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 15))!

    @Test(arguments: [
        (TrafficPeriod.today, "2026-10-21", "2026-10-21"),
        (.week, "2026-10-19", "2026-10-25"),
        (.month, "2026-10-01", "2026-10-31"),
        (.year, "2026-01-01", "2026-12-31"),
    ])
    func periodCoversItsCalendarDays(period: TrafficPeriod, first: String, last: String) {
        let days = period.days(now: wednesday, custom: wednesday...wednesday, calendar: mondayFirst)
        #expect(days == TrafficDay(rawValue: first)...TrafficDay(rawValue: last))
    }

    @Test func weekStartsOnTheCalendarsFirstWeekday() {
        var sundayFirst = mondayFirst
        sundayFirst.firstWeekday = 1
        #expect(TrafficPeriod.week.days(now: wednesday, custom: wednesday...wednesday, calendar: sundayFirst).lowerBound == TrafficDay(rawValue: "2026-10-18"))
    }

    @Test func customCoversFromThroughTo() {
        let from = utc.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 23))!
        let days = TrafficPeriod.custom.days(now: wednesday, custom: from...wednesday, calendar: mondayFirst)
        #expect(days == TrafficDay(rawValue: "2026-09-30")...TrafficDay(rawValue: "2026-10-21"))
    }
}

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private let mondayFirst: Calendar = {
    var calendar = utc
    calendar.firstWeekday = 2
    return calendar
}()

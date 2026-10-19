import Foundation
import UnlocalFSDomain

public enum TrafficPeriod: Hashable, CaseIterable, Sendable {
    case today, week, month, year, custom

    public func days(now: Date, custom: ClosedRange<Date>, calendar: Calendar) -> ClosedRange<TrafficDay> {
        let range = switch self {
        case .today: now...now
        case .week: dates(of: .weekOfYear, now: now, calendar: calendar)
        case .month: dates(of: .month, now: now, calendar: calendar)
        case .year: dates(of: .year, now: now, calendar: calendar)
        case .custom: custom
        }
        return TrafficDay(range.lowerBound, calendar: calendar)...TrafficDay(range.upperBound, calendar: calendar)
    }

    private func dates(of component: Calendar.Component, now: Date, calendar: Calendar) -> ClosedRange<Date> {
        let interval = calendar.dateInterval(of: component, for: now) ?? DateInterval(start: now, duration: 0)
        return interval.start...interval.end.addingTimeInterval(-1)
    }
}

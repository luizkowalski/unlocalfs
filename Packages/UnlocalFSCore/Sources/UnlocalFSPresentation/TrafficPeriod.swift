import Foundation
import UnlocalFSDomain

public enum TrafficPeriod: Hashable, Sendable {
    case last30Days, last90Days, last12Months, custom

    public func interval(now: Date, custom: ClosedRange<Date>, calendar: Calendar) -> DateInterval {
        let tomorrow = calendar.startOfDay(for: now).adding(.day, 1, calendar)
        return switch self {
        case .last30Days: DateInterval(start: tomorrow.adding(.day, -30, calendar), end: tomorrow)
        case .last90Days: DateInterval(start: tomorrow.adding(.day, -90, calendar), end: tomorrow)
        case .last12Months: DateInterval(start: now.start(of: .month, calendar).adding(.month, -11, calendar), end: tomorrow)
        case .custom: DateInterval(start: calendar.startOfDay(for: custom.lowerBound), end: calendar.startOfDay(for: custom.upperBound).adding(.day, 1, calendar))
        }
    }
}

public enum TrafficPreset: CaseIterable, Sendable {
    case today, yesterday, last7Days, thisMonth, lastMonth, thisYear

    public func days(now: Date, calendar: Calendar) -> ClosedRange<Date> {
        let today = calendar.startOfDay(for: now)
        let month = now.start(of: .month, calendar)
        return switch self {
        case .today: today...today
        case .yesterday: today.adding(.day, -1, calendar)...today.adding(.day, -1, calendar)
        case .last7Days: today.adding(.day, -6, calendar)...today
        case .thisMonth: month...today
        case .lastMonth: month.adding(.month, -1, calendar)...month.adding(.day, -1, calendar)
        case .thisYear: now.start(of: .year, calendar)...today
        }
    }
}

public struct TrafficBar: Identifiable, Equatable, Sendable {
    public let interval: DateInterval
    public let traffic: Traffic

    public var id: Date { interval.start }
}

extension Date {
    func adding(_ component: Calendar.Component, _ value: Int, _ calendar: Calendar) -> Date {
        calendar.date(byAdding: component, value: value, to: self) ?? self
    }

    func start(of component: Calendar.Component, _ calendar: Calendar) -> Date {
        calendar.dateInterval(of: component, for: self)?.start ?? calendar.startOfDay(for: self)
    }
}

extension DateInterval {
    func days(_ calendar: Calendar) -> ClosedRange<TrafficDay> {
        TrafficDay(start, calendar: calendar)...TrafficDay(end.addingTimeInterval(-1), calendar: calendar)
    }
}

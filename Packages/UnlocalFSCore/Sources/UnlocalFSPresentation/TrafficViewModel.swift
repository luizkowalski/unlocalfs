import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class TrafficViewModel {
    public var period = TrafficPeriod.last30Days { didSet { showAll() } }
    public var custom: ClosedRange<Date> { didSet { showAll() } }
    public private(set) var interval = DateInterval()
    public private(set) var bars: [TrafficBar] = []
    public private(set) var recent: [TrafficBar] = []
    public private(set) var picked: DateInterval?
    public private(set) var rows: [DriveTraffic] = []
    public private(set) var quiet: [String] = []
    public private(set) var error: String?

    private let repository: any TrafficRepository
    private let connections: () -> [Connection]
    private let unsaved: () -> [UUID: Traffic]

    init(repository: any TrafficRepository, connections: @escaping () -> [Connection], unsaved: @escaping () -> [UUID: Traffic]) {
        self.repository = repository
        self.connections = connections
        self.unsaved = unsaved
        custom = TrafficPreset.thisMonth.days(now: .now, calendar: .current)
    }

    public var unit: Calendar.Component { interval.duration > 92 * 86_400 ? .month : .day }
    public var total: Traffic? { error == nil ? rows.reduce(Traffic()) { $0 + $1.traffic } : nil }
    public var recentTotal: Traffic { recent.reduce(Traffic()) { $0 + $1.traffic } }

    public func pick(_ dates: ClosedRange<Date>) {
        let touched = bars.filter { $0.interval.end > dates.lowerBound && $0.interval.start <= dates.upperBound }
        guard let first = touched.first, let last = touched.last else { return }
        picked = DateInterval(start: first.interval.start, end: last.interval.end)
        reload()
    }

    public func highlights(_ bar: TrafficBar) -> Bool {
        guard let picked else { return true }
        return bar.interval.start < picked.end && picked.start < bar.interval.end
    }

    public func showAll() {
        picked = nil
        reload()
    }

    public func reload() {
        let now = Date.now
        let calendar = Calendar.current
        interval = period.interval(now: now, custom: custom, calendar: calendar)
        do {
            bars = try bars(in: interval, unit: unit, now: now, calendar: calendar)
            recent = try bars(in: TrafficPeriod.last30Days.interval(now: now, custom: custom, calendar: calendar), unit: .day, now: now, calendar: calendar)
            let all = try rows(in: (picked ?? interval).days(calendar), now: now, calendar: calendar)
            rows = all.filter { $0.traffic.total > 0 }
            quiet = all.filter { $0.traffic.total == 0 }.map(\.name)
            error = nil
        } catch {
            bars = []
            recent = []
            rows = []
            quiet = []
            self.error = error.localizedDescription
        }
    }

    private func bars(in interval: DateInterval, unit: Calendar.Component, now: Date, calendar: Calendar) throws -> [TrafficBar] {
        let days = interval.days(calendar)
        var daily = try repository.dailyTraffic(in: days)
        let today = TrafficDay(now, calendar: calendar)
        if days.contains(today) { daily[today] = (daily[today] ?? Traffic()) + unsaved().values.reduce(Traffic(), +) }
        var bars: [TrafficBar] = []
        var start = interval.start
        while start < interval.end {
            let end = min(start.start(of: unit, calendar).adding(unit, 1, calendar), interval.end)
            let traffic = sequence(first: start) { $0.adding(.day, 1, calendar) }
                .prefix { $0 < end }
                .reduce(Traffic()) { $0 + (daily[TrafficDay($1, calendar: calendar)] ?? Traffic()) }
            bars.append(TrafficBar(interval: DateInterval(start: start, end: end), traffic: traffic))
            start = end
        }
        return bars
    }

    private func rows(in days: ClosedRange<TrafficDay>, now: Date, calendar: Calendar) throws -> [DriveTraffic] {
        var traffic = Dictionary(uniqueKeysWithValues: try repository.traffic(in: days).map { ($0.id, $0) })
        let pending = days.contains(TrafficDay(now, calendar: calendar)) ? unsaved() : [:]
        for connection in connections() {
            let saved = traffic[connection.id]?.traffic ?? Traffic()
            traffic[connection.id] = DriveTraffic(
                id: connection.id, name: connection.name, provider: connection.provider, traffic: saved + (pending[connection.id] ?? Traffic())
            )
        }
        return traffic.values.sorted {
            if $0.traffic.total != $1.traffic.total { return $0.traffic.total > $1.traffic.total }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}

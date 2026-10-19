import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class TrafficViewModel {
    public var period = TrafficPeriod.month { didSet { reload() } }
    public private(set) var rows: [DriveTraffic] = []
    public private(set) var error: String?
    private var customRange: ClosedRange<Date> { didSet { if period == .custom { reload() } } }

    private let repository: any TrafficRepository
    private let connections: () -> [Connection]
    private let unsaved: () -> [UUID: Traffic]

    init(repository: any TrafficRepository, connections: @escaping () -> [Connection], unsaved: @escaping () -> [UUID: Traffic]) {
        self.repository = repository
        self.connections = connections
        self.unsaved = unsaved
        let now = Date.now
        customRange = (Calendar.current.date(byAdding: .day, value: -20, to: now) ?? now)...now
    }

    public var total: Traffic? { error == nil ? rows.reduce(Traffic()) { $0 + $1.traffic } : nil }

    public var start: Date {
        get { customRange.lowerBound }
        set {
            let start = min(newValue, .now)
            customRange = start...max(start, customRange.upperBound)
        }
    }

    public var end: Date {
        get { customRange.upperBound }
        set {
            let end = min(newValue, .now)
            customRange = min(customRange.lowerBound, end)...end
        }
    }

    public func reload() {
        let now = Date.now
        let calendar = Calendar.current
        let days = period.days(now: now, custom: customRange, calendar: calendar)
        do {
            var traffic = Dictionary(uniqueKeysWithValues: try repository.traffic(from: days.lowerBound, through: days.upperBound).map { ($0.id, $0) })
            let pending = days.contains(TrafficDay(now, calendar: calendar)) ? unsaved() : [:]
            for connection in connections() {
                let saved = traffic[connection.id]?.traffic ?? Traffic()
                traffic[connection.id] = DriveTraffic(
                    id: connection.id, name: connection.name, provider: connection.provider, traffic: saved + (pending[connection.id] ?? Traffic())
                )
            }
            rows = traffic.values.sorted {
                $0.traffic.total == $1.traffic.total ? $0.name.localizedStandardCompare($1.name) == .orderedAscending : $0.traffic.total > $1.traffic.total
            }
            error = nil
        } catch {
            rows = []
            self.error = error.localizedDescription
        }
    }
}

import Foundation

public struct RcloneProcess: Equatable, Sendable {
    public let pid: Int32
    public let startedAt: Date

    public init(pid: Int32, startedAt: Date) {
        self.pid = pid
        self.startedAt = startedAt
    }
}

public struct TrafficReading: Equatable, Sendable {
    public let process: RcloneProcess
    public let network: Int64
    public let uploaded: Int64
    public let date: Date

    public init(process: RcloneProcess, network: Int64, uploaded: Int64, date: Date) {
        self.process = process
        self.network = network
        self.uploaded = uploaded
        self.date = date
    }
}

public struct TrafficCheckpoint: Equatable, Sendable {
    public let process: RcloneProcess
    public let network: Int64
    public let uploaded: Int64
    public let savedAt: Date

    public init(process: RcloneProcess, network: Int64, uploaded: Int64, savedAt: Date) {
        self.process = process
        self.network = network
        self.uploaded = uploaded
        self.savedAt = savedAt
    }
}

public struct TrafficSave: Equatable, Sendable {
    public let day: TrafficDay
    public let traffic: Traffic
    public let checkpoint: TrafficCheckpoint

    public init(day: TrafficDay, traffic: Traffic, checkpoint: TrafficCheckpoint) {
        self.day = day
        self.traffic = traffic
        self.checkpoint = checkpoint
    }
}

public struct TrafficMeter: Sendable {
    private static let saveInterval: TimeInterval = 3_600

    public private(set) var checkpoint: TrafficCheckpoint?
    private var latest: TrafficReading?
    private var lastSave: Date?

    public init(checkpoint: TrafficCheckpoint?) {
        self.checkpoint = checkpoint
        lastSave = checkpoint?.savedAt
    }

    public var unsaved: Traffic { latest.map(traffic) ?? Traffic() }

    public mutating func read(_ reading: TrafficReading, calendar: Calendar) -> TrafficSave? {
        guard !isStale(reading) else { return nil }
        let previous = latest
        latest = reading
        if let previous, TrafficDay(previous.date, calendar: calendar) != TrafficDay(reading.date, calendar: calendar) {
            return save(through: previous, calendar: calendar)
        }
        let lastSave = lastSave ?? reading.date
        self.lastSave = lastSave
        return reading.date.timeIntervalSince(lastSave) >= Self.saveInterval ? save(through: reading, calendar: calendar) : nil
    }

    public mutating func save(calendar: Calendar) -> TrafficSave? {
        guard let latest else { return nil }
        return save(through: latest, calendar: calendar)
    }

    private mutating func save(through reading: TrafficReading, calendar: Calendar) -> TrafficSave? {
        lastSave = reading.date
        let traffic = traffic(to: reading)
        guard traffic != Traffic() else { return nil }
        let save = TrafficSave(
            day: TrafficDay(reading.date, calendar: calendar), traffic: traffic,
            checkpoint: TrafficCheckpoint(process: reading.process, network: reading.network, uploaded: reading.uploaded, savedAt: reading.date)
        )
        checkpoint = save.checkpoint
        return save
    }

    private func traffic(to reading: TrafficReading) -> Traffic {
        let base = checkpoint?.process == reading.process ? checkpoint : nil
        let network = reading.network - (base?.network ?? 0)
        let upload = min(max(reading.uploaded - (base?.uploaded ?? 0), 0), network)
        return Traffic(upload: upload, download: network - upload)
    }

    private func isStale(_ reading: TrafficReading) -> Bool {
        let newest = latest.map { ($0.process, $0.network) } ?? checkpoint.map { ($0.process, $0.network) }
        guard let newest, newest.0 == reading.process else { return false }
        return reading.network < newest.1
    }
}

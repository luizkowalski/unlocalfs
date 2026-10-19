import Foundation

public struct Traffic: Equatable, Sendable {
    public var upload: Int64
    public var download: Int64

    public init(upload: Int64 = 0, download: Int64 = 0) {
        self.upload = upload
        self.download = download
    }

    public var total: Int64 { upload + download }

    public static func + (lhs: Traffic, rhs: Traffic) -> Traffic {
        Traffic(upload: lhs.upload + rhs.upload, download: lhs.download + rhs.download)
    }
}

public struct TrafficDay: Hashable, Comparable, Sendable {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }

    public init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        rawValue = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    public static func < (lhs: TrafficDay, rhs: TrafficDay) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct DriveTraffic: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let provider: Provider
    public let traffic: Traffic

    public init(id: UUID, name: String, provider: Provider, traffic: Traffic) {
        self.id = id
        self.name = name
        self.provider = provider
        self.traffic = traffic
    }
}

public protocol TrafficRepository: Sendable {
    func traffic(from first: TrafficDay, through last: TrafficDay) throws -> [DriveTraffic]
}

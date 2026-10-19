import Foundation

public struct UnfinishedUpload: Equatable, Sendable {
    public static let abandonedAge: TimeInterval = 24 * 60 * 60

    public let key: String
    public let startedAt: Date

    public init(key: String, startedAt: Date) {
        self.key = key
        self.startedAt = startedAt
    }

    public func isAbandoned(at date: Date) -> Bool {
        date.timeIntervalSince(startedAt) > Self.abandonedAge
    }
}

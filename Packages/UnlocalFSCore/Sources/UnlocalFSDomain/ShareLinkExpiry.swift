public enum ShareLinkExpiry: String, Sendable {
    case hour = "1h"
    case day = "1d"
    case week = "1w"

    public var title: String {
        switch self {
        case .hour: "1 hour"
        case .day: "1 day"
        case .week: "7 days"
        }
    }
}

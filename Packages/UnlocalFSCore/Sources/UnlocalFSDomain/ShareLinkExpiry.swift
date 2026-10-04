public enum ShareLinkExpiry: String, Sendable {
    case hour = "1h"
    case day = "1d"
    case week = "1w"

    public var title: String {
        switch self {
        case .hour: L10n.oneHour
        case .day: L10n.oneDay
        case .week: L10n.sevenDays
        }
    }
}

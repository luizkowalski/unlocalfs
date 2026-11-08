import Foundation
import UnlocalFSDomain

public enum ActivitySnapshot: Equatable, Sendable {
    case checking
    case idle
    case transfers(TransferSummary)
    case unavailable(String)

    public var files: [FileActivity] {
        guard case let .transfers(summary) = self else { return [] }
        return summary.files
    }
}

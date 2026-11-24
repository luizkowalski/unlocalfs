import Foundation
import UnlocalFSDomain

public enum ActivitySnapshot: Equatable, Sendable {
    case checking
    case idle
    case transfers(TransferSummary)
    case unavailable(String)

    public var moving: TransferSummary? {
        guard case let .transfers(summary) = self, summary.fileCount > 0 else { return nil }
        return summary
    }

    public var files: [FileActivity] {
        guard case let .transfers(summary) = self else { return [] }
        return summary.files
    }
}

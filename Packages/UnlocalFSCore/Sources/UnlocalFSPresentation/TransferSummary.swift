import Foundation
import UnlocalFSDomain

public struct TransferSummary {
    public let isUploading: Bool
    public let fileCount: Int
    public let files: [FileActivity]

    public init?(_ activity: [FileActivity], now: Date) {
        let shown = activity.filter { $0.finishedAt.map { now.timeIntervalSince($0) < 10 } ?? true }
        guard !shown.isEmpty else { return nil }
        let moving = shown.filter { $0.finishedAt == nil && !$0.hasFailed }
        let uploads = moving.filter { $0.state != .downloading }
        let leading = uploads.isEmpty ? moving : uploads
        isUploading = !uploads.isEmpty
        fileCount = leading.count
        let byName = [KeyPathComparator(\FileActivity.path, comparator: .localizedStandard), KeyPathComparator(\FileActivity.id)]
        files = shown.sorted(using: [KeyPathComparator(\.failedFirst)] + byName)
    }
}

private extension FileActivity {
    var hasFailed: Bool { if case .failed = state { true } else { false } }

    var failedFirst: Int { hasFailed ? 0 : 1 }

    var finishedAt: Date? {
        switch state {
        case .uploaded(let date), .downloaded(let date): date
        case .queued, .uploading, .failed, .downloading: nil
        }
    }
}

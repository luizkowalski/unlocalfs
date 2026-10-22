import Foundation
import UnlocalFSDomain

public struct TransferSummary {
    private static let showForSeconds: TimeInterval = 30

    public let isUploading: Bool
    public let fileCount: Int
    public let files: [FileActivity]

    public init?(_ activity: [FileActivity], now: Date) {
        let shown = activity.filter { $0.finishedAt.map { now.timeIntervalSince($0) < Self.showForSeconds } ?? true }
        guard !shown.isEmpty else { return nil }
        let moving = shown.filter { $0.finishedAt == nil && !$0.hasFailed }
        let uploads = moving.filter { $0.state != .downloading }
        let leading = uploads.isEmpty ? moving : uploads
        isUploading = !uploads.isEmpty
        fileCount = leading.count
        let byName = [KeyPathComparator(\FileActivity.path, comparator: .localizedStandard), KeyPathComparator(\FileActivity.id)]
        files = shown.sorted(using: [KeyPathComparator(\.rank)] + byName)
    }
}

private extension FileActivity {
    var hasFailed: Bool { if case .failed = state { true } else { false } }

    var rank: Int {
        switch state {
        case .failed: 0
        case .uploading, .downloading: 1
        case .queued: 2
        case .uploaded, .downloaded: 3
        }
    }

    var finishedAt: Date? {
        switch state {
        case .uploaded(let date), .downloaded(let date): date
        case .queued, .uploading, .failed, .downloading: nil
        }
    }
}

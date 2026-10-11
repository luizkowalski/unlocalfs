import Foundation
import UnlocalFSDomain

public struct TransferSummary {
    public let isUploading: Bool
    public let fileCount: Int
    public let bytesPerSecond: Int64?
    public let files: [FileActivity]
    public let hiddenFileCount: Int

    public init?(_ activity: [FileActivity], now: Date) {
        let shown = activity.filter { $0.finishedAt.map { now.timeIntervalSince($0) < 10 } ?? true }
        guard !shown.isEmpty else { return nil }
        let moving = shown.filter { $0.finishedAt == nil }
        let uploads = moving.filter { $0.state != .downloading }
        let leading = uploads.isEmpty ? moving : uploads
        isUploading = !uploads.isEmpty
        fileCount = leading.count
        let speed = Int64(leading.reduce(0) { $0 + ($1.bytesPerSecond ?? 0) }.rounded())
        bytesPerSecond = speed > 0 ? speed : nil
        let byName = [KeyPathComparator(\FileActivity.path, comparator: .localizedStandard), KeyPathComparator(\FileActivity.id)]
        files = shown.sorted(using: [KeyPathComparator(\.listOrder)] + byName).prefix(10).sorted(using: byName)
        hiddenFileCount = shown.count - files.count
    }
}

private extension FileActivity {
    var listOrder: Int {
        switch state {
        case .uploading: 0
        case .downloading: 1
        case .failed: 2
        case .queued: 3
        case .uploaded, .downloaded: 4
        }
    }

    var finishedAt: Date? {
        switch state {
        case .uploaded(let date), .downloaded(let date): date
        case .queued, .uploading, .failed, .downloading: nil
        }
    }
}

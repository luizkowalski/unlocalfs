import Foundation
import UnlocalFSDomain

public struct TransferSummary {
    public let isUploading: Bool
    public let fileCount: Int
    public let bytesPerSecond: Int64?
    public let files: [FileActivity]
    public let hiddenFileCount: Int

    public init?(_ activity: [FileActivity], now: Date) {
        let shown = activity.filter { file in
            guard case .uploaded(let date) = file.state else { return true }
            return now.timeIntervalSince(date) < 5
        }
        guard !shown.isEmpty else { return nil }
        let moving = shown.filter { !$0.isUploaded }
        let uploads = moving.filter { $0.state != .downloading }
        let leading = uploads.isEmpty ? moving : uploads
        isUploading = !uploads.isEmpty
        fileCount = leading.count
        let speed = Int64(leading.reduce(0) { $0 + ($1.bytesPerSecond ?? 0) }.rounded())
        bytesPerSecond = speed > 0 ? speed : nil
        files = Array(shown.sorted(using: [KeyPathComparator(\.listOrder), KeyPathComparator(\.path, comparator: .localizedStandard)]).prefix(10))
        hiddenFileCount = shown.count - files.count
    }
}

private extension FileActivity {
    var listOrder: Int {
        switch state {
        case .uploading: 0
        case .downloading: 1
        case .retrying: 2
        case .queued: 3
        case .uploaded: 4
        }
    }

    var isUploaded: Bool {
        if case .uploaded = state { true } else { false }
    }
}

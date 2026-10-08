import Foundation
import UnlocalFSDomain

public struct TransferSummary {
    public let isUploading: Bool
    public let fileCount: Int
    public let bytesDone: Int64
    public let bytesTotal: Int64
    public let files: [FileActivity]
    public let hiddenFileCount: Int

    public init?(_ activity: [FileActivity]) {
        let uploads = activity.filter { $0.state != .downloading }
        let leading = uploads.isEmpty ? activity : uploads
        guard !leading.isEmpty else { return nil }
        let sized = uploads.filter { $0.size > 0 }
        isUploading = !uploads.isEmpty
        fileCount = leading.count
        bytesDone = sized.reduce(0) { $0 + ($1.bytesTransferred ?? 0) }
        bytesTotal = sized.reduce(0) { $0 + $1.size }
        files = Array(activity.sorted(using: [KeyPathComparator(\.listOrder), KeyPathComparator(\.path, comparator: .localizedStandard)]).prefix(10))
        hiddenFileCount = activity.count - files.count
    }

    public var bytesLeft: Int64 { bytesTotal - bytesDone }
}

private extension FileActivity {
    var listOrder: Int {
        switch state {
        case .uploading: 0
        case .downloading: 1
        case .retrying: 2
        case .queued: 3
        }
    }
}

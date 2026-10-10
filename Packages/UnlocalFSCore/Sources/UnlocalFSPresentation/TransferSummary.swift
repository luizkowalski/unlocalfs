import Foundation
import UnlocalFSDomain

public struct TransferSummary {
    public let isUploading: Bool
    public let fileCount: Int
    private let bytesDone: Int64
    public let bytesTotal: Int64
    public let bytesPerSecond: Int64?
    public let timeLeft: Duration?
    public let files: [FileActivity]
    public let hiddenFileCount: Int
    public let finderFileCount: Int

    public init?(_ activity: [FileActivity]) {
        let uploads = activity.filter { $0.state != .downloading }
        let leading = uploads.isEmpty ? activity : uploads
        guard !leading.isEmpty else { return nil }
        let sized = uploads.filter { $0.size > 0 }
        isUploading = !uploads.isEmpty
        fileCount = leading.count
        bytesDone = sized.reduce(0) { $0 + ($1.bytesTransferred ?? 0) }
        bytesTotal = sized.reduce(0) { $0 + $1.size }
        let speed = Int64(leading.reduce(0) { $0 + ($1.bytesPerSecond ?? 0) }.rounded())
        bytesPerSecond = speed > 0 ? speed : nil
        let sizedSpeed = sized.reduce(0) { $0 + ($1.bytesPerSecond ?? 0) }
        let secondsLeft = sizedSpeed > 0 ? Double(bytesTotal - bytesDone) / sizedSpeed : 0
        timeLeft = secondsLeft >= 1 ? .seconds(secondsLeft) : nil
        let listed = activity.filter { !$0.isFinderMetadata }
            .sorted(using: [KeyPathComparator(\.listOrder), KeyPathComparator(\.path, comparator: .localizedStandard)])
        files = Array((listed.filter { $0.state != .queued } + listed.filter { $0.state == .queued }.prefix(3)).prefix(10))
        hiddenFileCount = listed.count - files.count
        finderFileCount = activity.count - listed.count
    }

    public var bytesLeft: Int64 { bytesTotal - bytesDone }
}

private extension FileActivity {
    var isFinderMetadata: Bool {
        let name = (path as NSString).lastPathComponent
        return name == ".DS_Store" || name.hasPrefix("._")
    }

    var listOrder: Int {
        switch state {
        case .uploading: 0
        case .downloading: 1
        case .retrying: 2
        case .queued: 3
        }
    }
}

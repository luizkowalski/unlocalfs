import UnlocalFSDomain

public struct TransferSummary {
    public let isUploading: Bool
    public let fileCount: Int
    public let bytesDone: Int64
    public let bytesTotal: Int64

    public init?(_ activity: [FileActivity]) {
        let uploads = activity.filter { $0.state != .downloading }
        let shown = uploads.isEmpty ? activity : uploads
        guard !shown.isEmpty else { return nil }
        let sized = shown.filter { $0.size > 0 }
        isUploading = !uploads.isEmpty
        fileCount = shown.count
        bytesDone = sized.reduce(0) { $0 + ($1.bytesTransferred ?? 0) }
        bytesTotal = sized.reduce(0) { $0 + $1.size }
    }

    public var bytesLeft: Int64 { bytesTotal - bytesDone }
}

import Foundation

public struct FileActivity: Identifiable, Equatable, Sendable {
    public enum State: Sendable {
        case queued, uploading, retrying, downloading
    }

    public let path: String
    public let size: Int64
    public let state: State
    public let bytesTransferred: Int64?

    public var id: String { "\(state == .downloading ? "download" : "upload"):\(path)" }
}

struct UploadQueue: Decodable {
    let queue: [Item]

    struct Item: Decodable {
        let name: String
        let size: Int64
        let tries: Int
        let uploading: Bool
    }
}

struct TransferStats: Decodable {
    let transferring: [Transfer]?

    struct Transfer: Decodable {
        let name: String
        let size: Int64
        let bytes: Int64?
        let dstFs: String?

        var isUpload: Bool { dstFs != nil }
    }
}

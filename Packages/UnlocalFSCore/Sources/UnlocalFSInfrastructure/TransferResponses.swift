import Foundation

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
        let speedAvg: Double?
        let dstFs: String?

        var isUpload: Bool { dstFs != nil }
    }
}

struct VFSStats: Decodable {
    let diskCache: DiskCache

    struct DiskCache: Decodable {
        let uploadsQueued: Int
        let uploadsInProgress: Int
        let erroredFiles: Int
        let bytesUsed: Int64
    }
}

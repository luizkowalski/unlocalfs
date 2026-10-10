import Foundation
import UnlocalFSDomain

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

struct ControlSnapshot: Decodable {
    let cache: VFSStats.DiskCache
    let queue: [UploadQueue.Item]
    let transfers: [TransferStats.Transfer]

    private enum CodingKeys: CodingKey { case results }

    init(from decoder: any Decoder) throws {
        var results = try decoder.container(keyedBy: CodingKeys.self).nestedUnkeyedContainer(forKey: .results)
        cache = try results.decode(BatchResult<VFSStats>.self).value.diskCache
        queue = try results.decode(BatchResult<UploadQueue>.self).value.queue
        transfers = try results.decode(BatchResult<TransferStats>.self).value.transferring ?? []
    }
}

private struct BatchResult<Value: Decodable>: Decodable {
    let value: Value

    private enum CodingKeys: CodingKey { case error }

    init(from decoder: any Decoder) throws {
        if let error = try decoder.container(keyedBy: CodingKeys.self).decodeIfPresent(String.self, forKey: .error) {
            throw AppError(error)
        }
        value = try Value(from: decoder)
    }
}

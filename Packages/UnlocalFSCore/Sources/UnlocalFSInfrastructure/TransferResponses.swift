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

struct FinishedTransfers: Decodable {
    let transferred: [FinishedTransfer]
}

struct FinishedTransfer: Decodable {
    let name: String
    let size: Int64
    let error: String
    let dstFs: String?
    let completedAt: Date

    private enum CodingKeys: String, CodingKey {
        case name, size, error, dstFs
        case completedAt = "completed_at"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        size = try container.decode(Int64.self, forKey: .size)
        error = try container.decode(String.self, forKey: .error)
        dstFs = try container.decodeIfPresent(String.self, forKey: .dstFs)
        completedAt = try Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(container.decode(String.self, forKey: .completedAt))
    }

    var isUpload: Bool { dstFs != nil }
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
    static let statusRequest = #"{"inputs":[{"_path":"vfs/stats"},{"_path":"vfs/queue"},{"_path":"core/stats"}]}"#
    static let activityRequest = #"{"inputs":[{"_path":"vfs/stats"},{"_path":"vfs/queue"},{"_path":"core/stats"},{"_path":"core/transferred"}]}"#

    let cache: VFSStats.DiskCache
    let queue: [UploadQueue.Item]
    let transfers: [TransferStats.Transfer]
    let finished: [FinishedTransfer]

    private enum CodingKeys: CodingKey { case results }

    init(from decoder: any Decoder) throws {
        var results = try decoder.container(keyedBy: CodingKeys.self).nestedUnkeyedContainer(forKey: .results)
        cache = try results.decode(BatchResult<VFSStats>.self).value.diskCache
        queue = try results.decode(BatchResult<UploadQueue>.self).value.queue
        transfers = try results.decode(BatchResult<TransferStats>.self).value.transferring ?? []
        finished = results.isAtEnd ? [] : try results.decode(BatchResult<FinishedTransfers>.self).value.transferred
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

struct StartedJob: Decodable {
    let jobid: Int
}

struct JobStatus: Decodable {
    let finished: Bool
    let success: Bool
    let error: String
    let group: String?
}

struct JobList: Decodable {
    let runningIds: [Int]
}

struct RemoteItem: Decodable {
    struct Item: Decodable {}

    let item: Item?
}

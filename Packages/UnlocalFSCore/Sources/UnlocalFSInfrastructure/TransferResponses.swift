import Foundation
import UnlocalFSDomain

struct UploadQueue: Decodable {
    let queue: [Item]

    struct Item: Decodable {
        let name: String
        let size: Int64
        let expiry: Double
        let tries: Int
        let uploading: Bool

        var hasFailedAttempt: Bool { tries > 1 || (tries > 0 && !uploading) }
    }
}

struct TransferStats: Decodable {
    let transferring: [Transfer]?
    let lastError: String?
    let bytes: Int64
    let serverSideCopyBytes: Int64
    let serverSideMoveBytes: Int64

    var networkBytes: Int64 { bytes - serverSideCopyBytes - serverSideMoveBytes }

    struct Transfer: Decodable {
        let name: String
        let size: Int64
        let bytes: Int64?
        let speedAvg: Double?
        let srcFs: String?
        let dstFs: String?

        var isUpload: Bool { dstFs != nil }
        var isServerSide: Bool { srcFs == dstFs }
    }
}

struct FinishedTransfers: Decodable {
    let transferred: [FinishedTransfer]
}

struct FinishedTransfer: Decodable {
    let name: String
    let size: Int64
    let bytes: Int64
    let error: String
    let srcFs: String?
    let dstFs: String?
    let completedAt: Date

    private enum CodingKeys: String, CodingKey {
        case name, size, bytes, error, srcFs, dstFs
        case completedAt = "completed_at"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        size = try container.decode(Int64.self, forKey: .size)
        bytes = try container.decode(Int64.self, forKey: .bytes)
        error = try container.decode(String.self, forKey: .error)
        srcFs = try container.decodeIfPresent(String.self, forKey: .srcFs)
        dstFs = try container.decodeIfPresent(String.self, forKey: .dstFs)
        completedAt = try rcloneDate(container.decode(String.self, forKey: .completedAt))
    }

    var isUpload: Bool { dstFs != nil }
    var isServerSide: Bool { srcFs == dstFs }
}

struct VFSStats: Decodable {
    let diskCache: DiskCache

    struct DiskCache: Decodable {
        let uploadsQueued: Int
        let uploadsInProgress: Int
        let bytesUsed: Int64
    }
}

struct ControlSnapshot: Decodable {
    static let statusRequest = #"""
    {"inputs":[{"_path":"vfs/stats"},{"_path":"vfs/queue"},{"_path":"core/stats","group":"global_stats"},
    {"_path":"core/transferred","group":"global_stats"}]}
    """#
    static let activityRequest = #"{"inputs":[{"_path":"vfs/stats"},{"_path":"vfs/queue"},{"_path":"core/stats"},{"_path":"core/transferred"}]}"#

    let cache: VFSStats.DiskCache
    let queue: [UploadQueue.Item]
    let transfers: [TransferStats.Transfer]
    let lastError: String?
    let networkBytes: Int64
    let finished: [FinishedTransfer]

    private enum CodingKeys: CodingKey { case results }

    init(from decoder: any Decoder) throws {
        var results = try decoder.container(keyedBy: CodingKeys.self).nestedUnkeyedContainer(forKey: .results)
        cache = try results.decode(BatchResult<VFSStats>.self).value.diskCache
        queue = try results.decode(BatchResult<UploadQueue>.self).value.queue
        let stats = try results.decode(BatchResult<TransferStats>.self).value
        transfers = stats.transferring ?? []
        lastError = stats.lastError
        networkBytes = stats.networkBytes
        finished = results.isAtEnd ? [] : try results.decode(BatchResult<FinishedTransfers>.self).value.transferred.sorted { $0.completedAt < $1.completedAt }
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

struct MultipartUploads: Decodable {
    let output: Output

    struct Output: Decodable {
        let result: [String: [MultipartUpload]?]
    }

    var uploads: [UnfinishedUpload] {
        output.result.values.flatMap { $0 ?? [] }.map { UnfinishedUpload(key: $0.key, startedAt: $0.initiated) }
    }
}

struct MultipartUpload: Decodable {
    let key: String
    let initiated: Date

    private enum CodingKeys: String, CodingKey {
        case key = "Key"
        case initiated = "Initiated"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        initiated = try rcloneDate(container.decode(String.self, forKey: .initiated))
    }
}

private func rcloneDate(_ string: String) throws -> Date {
    try (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string)) ?? Date.ISO8601FormatStyle().parse(string)
}

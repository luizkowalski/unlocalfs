import Foundation

public struct Connection: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var provider = Provider.other
    public var endpoint = ""
    public var region = "us-east-1"
    public var bucket = ""
    public var cacheLimit: Int64 = 128_000_000
    public var minimumFreeSpace: Int64 = 0

    public init() {}

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        provider = try container.decode(Provider.self, forKey: .provider)
        endpoint = try container.decode(String.self, forKey: .endpoint)
        region = try container.decode(String.self, forKey: .region)
        bucket = try container.decode(String.self, forKey: .bucket)
        cacheLimit = try container.decodeIfPresent(Int64.self, forKey: .cacheLimit) ?? cacheLimit
        minimumFreeSpace = try container.decodeIfPresent(Int64.self, forKey: .minimumFreeSpace) ?? minimumFreeSpace
    }

    public func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name != ".", name != "..", name.utf8.count <= 120,
              name.rangeOfCharacter(from: CharacterSet(charactersIn: "/:").union(.controlCharacters)) == nil else {
            throw AppError("Enter a drive name without slashes, colons, or control characters.")
        }
        guard let url = URLComponents(string: endpoint),
              ["http", "https"].contains(url.scheme),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/" else {
            throw AppError("Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query.")
        }
        guard !bucket.isEmpty, bucket != ".", bucket != "..",
              bucket.rangeOfCharacter(from: CharacterSet(charactersIn: "/:").union(.whitespacesAndNewlines).union(.controlCharacters)) == nil else {
            throw AppError("Enter the bucket name, without a path.")
        }
    }
}

public enum Provider: String, Codable, CaseIterable, Identifiable, Sendable {
    case other = "Other"
    case aws = "AWS"
    case cloudflare = "Cloudflare"
    case minio = "Minio"
    case wasabi = "Wasabi"
    case digitalOcean = "DigitalOcean"

    public var id: Self { self }

    public var title: String {
        switch self {
        case .other: "S3 compatible"
        case .aws: "Amazon S3"
        case .cloudflare: "Cloudflare R2"
        case .minio: "MinIO"
        case .wasabi: "Wasabi"
        case .digitalOcean: "DigitalOcean Spaces"
        }
    }
}

public struct Credentials: Codable, Equatable, Sendable {
    public var accessKey: String
    public var secretKey: String
    public var sessionToken: String

    public init(accessKey: String = "", secretKey: String = "", sessionToken: String = "") {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.sessionToken = sessionToken
    }

    public func validate() throws {
        guard !accessKey.isEmpty, !secretKey.isEmpty else { throw AppError("Enter an access key and secret key.") }
    }
}

public struct AppError: LocalizedError, Sendable {
    public let errorDescription: String?
    public init(_ message: String) { errorDescription = message }
}

import Foundation
import SwiftDataValidator

public struct Connection: Codable, Identifiable, Equatable, Sendable, Validatable {
    public var id = UUID()
    public var name = ""
    public var provider = Provider.other
    public var endpoint = ""
    public var region = "auto"
    public var bucket = ""
    public var folder = ""
    public var cacheLimit: Int64 = 128_000_000
    public var minimumFreeSpace: Int64 = 0
    public var connectsAutomatically = false
    public var readOnly = false

    public init() {}

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        provider = try container.decode(Provider.self, forKey: .provider)
        endpoint = try container.decode(String.self, forKey: .endpoint)
        region = try container.decode(String.self, forKey: .region)
        bucket = try container.decode(String.self, forKey: .bucket)
        folder = try container.decodeIfPresent(String.self, forKey: .folder) ?? folder
        cacheLimit = try container.decodeIfPresent(Int64.self, forKey: .cacheLimit) ?? cacheLimit
        minimumFreeSpace = try container.decodeIfPresent(Int64.self, forKey: .minimumFreeSpace) ?? minimumFreeSpace
        readOnly = try container.decodeIfPresent(Bool.self, forKey: .readOnly) ?? readOnly
        connectsAutomatically = try container.decodeIfPresent(Bool.self, forKey: .connectsAutomatically) ?? connectsAutomatically
    }

    public func validate() -> [ValidationError] {
        var validator = Validator()
        let forbiddenNameCharacters = CharacterSet(charactersIn: "/:").union(.controlCharacters)
        validator.validate(field: "Name", value: name) {
            $0.notEmpty()
            $0.custom({ _ in
                name != "." && name != ".." &&
                    name.rangeOfCharacter(from: forbiddenNameCharacters) == nil
            }, error: .custom(message: "Enter a drive name without slashes, colons, or control characters."))
            $0.custom({ _ in name.utf8.count <= 120 }, error: .custom(message: "Enter a shorter drive name. The limit is 120 bytes."))
        }
        validator.validate(field: "Endpoint", value: endpoint) {
            $0.matchesURL()
            $0.custom({ _ in
                guard let url = URLComponents(string: endpoint) else { return false }
                return ["http", "https"].contains(url.scheme) &&
                    url.host?.isEmpty == false && url.user == nil && url.password == nil &&
                    url.query == nil && url.fragment == nil && (url.path.isEmpty || url.path == "/")
            }, error: .custom(message: "Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."))
        }
        validator.validate(field: "Bucket", value: bucket) {
            $0.notEmpty()
            $0.custom({ _ in
                bucket != "." && bucket != ".." &&
                    bucket.rangeOfCharacter(from: forbiddenNameCharacters.union(.whitespacesAndNewlines)) == nil
            }, error: .custom(message: "Enter the bucket name, without a path."))
        }
        validator.validate(field: "Folder", value: folder) {
            $0.custom({ _ in
                (folder.isEmpty || folder.split(separator: "/", omittingEmptySubsequences: false).allSatisfy({ !["", ".", ".."].contains($0) })) &&
                    folder.rangeOfCharacter(from: .controlCharacters) == nil
            }, error: .custom(message: "Enter a folder path like clients/acme, or leave it empty to use the whole bucket."))
        }
        return validator.errors()
    }

    public func validate(against connections: [Connection]) -> [ValidationError] {
        var errors = validate()
        if connections.contains(where: { $0.id != id && $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            errors.append(ValidationError(field: "Name", rule: .custom(message: "A drive with that name already exists.")))
        }
        return errors
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

    public func validate() -> [ValidationError] {
        var validator = Validator()
        validator.validate(field: "Access key", value: accessKey) { $0.notEmpty() }
        validator.validate(field: "Secret key", value: secretKey) { $0.notEmpty() }
        return validator.errors()
    }
}

public struct AppError: LocalizedError, Sendable {
    public let errorDescription: String?
    public init(_ message: String) { errorDescription = message }

    public static func throwing(_ errors: [ValidationError]) throws {
        if !errors.isEmpty { throw AppError(errors.map(\.localizedDescription).joined(separator: "\n")) }
    }
}

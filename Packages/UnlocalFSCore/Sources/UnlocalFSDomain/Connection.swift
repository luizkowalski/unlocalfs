import Foundation

public struct Connection: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var provider = Provider.other
    public var endpoint = ""
    public var region = "auto"
    public var bucket = ""
    public var folder = ""
    public var cacheLimit: Int64 = 128_000_000
    public var minimumFreeSpace: Int64 = 0
    public var bandwidthLimit: Int64 = 0
    public var transfers = 4
    public var connectsAutomatically = false
    public var readOnly = false
    public var encrypted = false
    public var sftp = SFTPSettings()

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
        bandwidthLimit = try container.decodeIfPresent(Int64.self, forKey: .bandwidthLimit) ?? bandwidthLimit
        transfers = try container.decodeIfPresent(Int.self, forKey: .transfers) ?? transfers
        readOnly = try container.decodeIfPresent(Bool.self, forKey: .readOnly) ?? readOnly
        encrypted = try container.decodeIfPresent(Bool.self, forKey: .encrypted) ?? encrypted
        connectsAutomatically = try container.decodeIfPresent(Bool.self, forKey: .connectsAutomatically) ?? connectsAutomatically
        sftp = try container.decodeIfPresent(SFTPSettings.self, forKey: .sftp) ?? sftp
    }

    public var backend: Backend { provider.backend }

    public var folderPath: String {
        switch backend {
        case .s3Compatible: folder
        case .sftp: sftp.remotePath
        }
    }

    public func shouldConnectAutomatically(status: MountStatus) -> Bool {
        connectsAutomatically && !status.isActive
    }

    private static let forbiddenNameCharacters = CharacterSet(charactersIn: "/:").union(.controlCharacters)

    public func validate() -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        result.check(!name.isBlank, field: .name, message: "Name cannot be empty")
        result.check(
            name != "." && name != ".." && name.rangeOfCharacter(from: Self.forbiddenNameCharacters) == nil,
            field: .name, message: "Enter a drive name without slashes, colons, or control characters."
        )
        result.check(name.utf8.count <= 120, field: .name, message: "Enter a shorter drive name. The limit is 120 bytes.")
        switch backend {
        case .s3Compatible: result.issues += validateStorage().issues
        case .sftp: result.issues += sftp.validate().issues
        }
        return result
    }

    private func validateStorage() -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        let url = URL(string: endpoint)
        result.check(url?.scheme?.isEmpty == false && url?.host != nil, field: .endpoint, message: "Endpoint must be a valid URL")
        let validEndpoint = URLComponents(string: endpoint).map { url in
            ["http", "https"].contains(url.scheme) &&
                url.host?.isEmpty == false && url.user == nil && url.password == nil &&
                url.query == nil && url.fragment == nil && (url.path.isEmpty || url.path == "/")
        } ?? false
        result.check(
            validEndpoint, field: .endpoint,
            message: "Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."
        )
        result.check(!bucket.isBlank, field: .bucket, message: "Bucket cannot be empty")
        result.check(
            bucket != "." && bucket != ".." &&
                bucket.rangeOfCharacter(from: Self.forbiddenNameCharacters.union(.whitespacesAndNewlines)) == nil,
            field: .bucket, message: "Enter the bucket name, without a path."
        )
        result.check(
            (folder.isEmpty || folder.split(separator: "/", omittingEmptySubsequences: false).allSatisfy({ !["", ".", ".."].contains($0) })) &&
                folder.rangeOfCharacter(from: .controlCharacters) == nil,
            field: .folder, message: "Enter a folder path like clients/acme, or leave it empty to use the whole bucket."
        )
        return result
    }

    public func validate(against connections: [Connection]) -> ValidationResult<ConnectionField> {
        var result = validate()
        result.check(
            !connections.contains(where: { $0.id != id && $0.name.caseInsensitiveCompare(name) == .orderedSame }),
            field: .name, message: "A drive with that name already exists."
        )
        return result
    }

    public func validate(credentials: Credentials, confirmation: String, against connections: [Connection]) -> ValidationResult<ConnectionField> {
        var result = validate(against: connections)
        result.issues += credentials.validate(for: self).issues
        if encrypted, !connections.contains(where: { $0.id == id }) {
            result.check(confirmation == credentials.encryptionPassword, field: .confirmation, message: "The passwords do not match.")
        }
        return result
    }
}

public enum ConnectionField: String, CaseIterable, Sendable {
    case name = "Name", endpoint = "Endpoint", bucket = "Bucket", folder = "Folder", accessKey = "Access key", secretKey = "Secret key"
    case host = "Host", port = "Port", username = "Username", remotePath = "Remote folder"
    case password = "Password", keyFile = "Private key", trustedHosts = "Trusted hosts"
    case encryptionPassword = "Encryption password", confirmation = "Confirm password"
}

public enum Provider: String, Codable, CaseIterable, Identifiable, Sendable {
    case other = "Other"
    case aws = "AWS"
    case cloudflare = "Cloudflare"
    case minio = "Minio"
    case wasabi = "Wasabi"
    case digitalOcean = "DigitalOcean"
    case sftp = "SFTP"

    public var id: Self { self }

    public var backend: Backend {
        switch self {
        case .other, .aws, .cloudflare, .minio, .wasabi, .digitalOcean: .s3Compatible
        case .sftp: .sftp
        }
    }

    public var title: String {
        switch self {
        case .other: "S3 compatible"
        case .aws: "Amazon S3"
        case .cloudflare: "Cloudflare R2"
        case .minio: "MinIO"
        case .wasabi: "Wasabi"
        case .digitalOcean: "DigitalOcean Spaces"
        case .sftp: "SFTP"
        }
    }
}

public struct Credentials: Codable, Equatable, Sendable {
    public var accessKey: String
    public var secretKey: String
    public var sessionToken: String
    public var encryptionPassword: String {
        didSet {
            if encryptionPassword != oldValue { obscuredEncryptionPassword = "" }
        }
    }
    public var obscuredEncryptionPassword = ""
    public var password: String {
        didSet {
            if password != oldValue { obscuredPassword = "" }
        }
    }
    public var obscuredPassword = ""
    public var keyPassphrase: String {
        didSet {
            if keyPassphrase != oldValue { obscuredKeyPassphrase = "" }
        }
    }
    public var obscuredKeyPassphrase = ""

    public init(
        accessKey: String = "", secretKey: String = "", sessionToken: String = "", encryptionPassword: String = "",
        password: String = "", keyPassphrase: String = ""
    ) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.sessionToken = sessionToken
        self.encryptionPassword = encryptionPassword
        self.password = password
        self.keyPassphrase = keyPassphrase
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessKey = try container.decode(String.self, forKey: .accessKey)
        secretKey = try container.decode(String.self, forKey: .secretKey)
        sessionToken = try container.decode(String.self, forKey: .sessionToken)
        encryptionPassword = try container.decodeIfPresent(String.self, forKey: .encryptionPassword) ?? ""
        obscuredEncryptionPassword = try container.decodeIfPresent(String.self, forKey: .obscuredEncryptionPassword) ?? ""
        password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        obscuredPassword = try container.decodeIfPresent(String.self, forKey: .obscuredPassword) ?? ""
        keyPassphrase = try container.decodeIfPresent(String.self, forKey: .keyPassphrase) ?? ""
        obscuredKeyPassphrase = try container.decodeIfPresent(String.self, forKey: .obscuredKeyPassphrase) ?? ""
    }

    public func pruned(for connection: Connection) -> Credentials {
        var credentials = self
        switch connection.backend {
        case .s3Compatible:
            credentials.password = ""
            credentials.keyPassphrase = ""
        case .sftp:
            credentials.accessKey = ""
            credentials.secretKey = ""
            credentials.sessionToken = ""
            if connection.sftp.authentication != .password { credentials.password = "" }
            if connection.sftp.authentication != .privateKey { credentials.keyPassphrase = "" }
        }
        return credentials
    }

    public func validate(for connection: Connection) -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        switch connection.backend {
        case .s3Compatible:
            result.check(!accessKey.isBlank, field: .accessKey, message: "Access key cannot be empty")
            result.check(!secretKey.isBlank, field: .secretKey, message: "Secret key cannot be empty")
        case .sftp:
            result.check(
                connection.sftp.authentication != .password || !password.isEmpty,
                field: .password, message: "Password cannot be empty"
            )
        }
        if connection.encrypted {
            result.check(!encryptionPassword.isBlank, field: .encryptionPassword, message: "Encryption password cannot be empty")
        }
        return result
    }
}

public struct AppError: LocalizedError, Sendable {
    public let errorDescription: String?
    public init(_ message: String) { errorDescription = message }
}

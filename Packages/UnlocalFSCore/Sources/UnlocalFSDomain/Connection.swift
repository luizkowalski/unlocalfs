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

    public var bucketPath: String { folder.isEmpty ? bucket : "\(bucket)/\(folder)" }

    public var folderPath: String {
        switch backend {
        case .s3Compatible, .gcs: folder
        case .sftp: sftp.remotePath
        }
    }

    public func shouldConnectAutomatically(status: MountStatus) -> Bool {
        connectsAutomatically && !status.isActive
    }

    private static let forbiddenNameCharacters = CharacterSet(charactersIn: "/:").union(.controlCharacters)

    public func validate() -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        result.check(!name.isBlank, field: .name, message: L10n.nameEmpty)
        result.check(
            name != "." && name != ".." && name.rangeOfCharacter(from: Self.forbiddenNameCharacters) == nil,
            field: .name, message: L10n.nameHasForbiddenCharacters
        )
        result.check(name.utf8.count <= 120, field: .name, message: L10n.nameTooLong)
        switch backend {
        case .s3Compatible: result.issues += validateEndpoint().issues + validateBucket().issues
        case .gcs: result.issues += validateBucket().issues
        case .sftp: result.issues += sftp.validate().issues
        }
        return result
    }

    private func validateEndpoint() -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        let url = URL(string: endpoint)
        result.check(url?.scheme?.isEmpty == false && url?.host != nil, field: .endpoint, message: L10n.endpointInvalidURL)
        let validEndpoint = URLComponents(string: endpoint).map { url in
            ["http", "https"].contains(url.scheme) &&
                url.host?.isEmpty == false && url.user == nil && url.password == nil &&
                url.query == nil && url.fragment == nil && (url.path.isEmpty || url.path == "/")
        } ?? false
        result.check(
            validEndpoint, field: .endpoint,
            message: L10n.endpointNotDirect
        )
        return result
    }

    private func validateBucket() -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        result.check(!bucket.isBlank, field: .bucket, message: L10n.bucketEmpty)
        result.check(
            bucket != "." && bucket != ".." &&
                bucket.rangeOfCharacter(from: Self.forbiddenNameCharacters.union(.whitespacesAndNewlines)) == nil,
            field: .bucket, message: L10n.bucketHasPath
        )
        result.check(
            (folder.isEmpty || folder.split(separator: "/", omittingEmptySubsequences: false).allSatisfy({ !["", ".", ".."].contains($0) })) &&
                folder.rangeOfCharacter(from: .controlCharacters) == nil,
            field: .folder, message: L10n.folderPathInvalid
        )
        return result
    }

    public func validate(against connections: [Connection]) -> ValidationResult<ConnectionField> {
        var result = validate()
        result.check(
            !connections.contains(where: { $0.id != id && $0.name.caseInsensitiveCompare(name) == .orderedSame }),
            field: .name, message: L10n.nameAlreadyExists
        )
        return result
    }

    public func validate(credentials: Credentials, confirmation: String, against connections: [Connection]) -> ValidationResult<ConnectionField> {
        var result = validate(against: connections)
        result.issues += credentials.validate(for: self).issues
        if encrypted, !connections.contains(where: { $0.id == id }) {
            result.check(confirmation == credentials.encryptionPassword, field: .confirmation, message: L10n.passwordsDoNotMatch)
        }
        return result
    }
}

public enum ConnectionField: String, CaseIterable, Sendable {
    case name = "Name", endpoint = "Endpoint", bucket = "Bucket", folder = "Folder", accessKey = "Access key", secretKey = "Secret key"
    case serviceAccountKey = "Service account key"
    case host = "Host", port = "Port", username = "Username", remotePath = "Remote folder"
    case password = "Password", keyFile = "Private key", trustedHosts = "Trusted hosts"
    case encryptionPassword = "Encryption password", confirmation = "Confirm password"

    /// Localized display label. Raw values stay stable identifiers because the
    /// editor renders them via `Text(field.rawValue)` until it adopts this.
    public var displayName: String {
        switch self {
        case .name: L10n.fieldName
        case .endpoint: L10n.fieldEndpoint
        case .bucket: L10n.fieldBucket
        case .folder: L10n.fieldFolder
        case .accessKey: L10n.fieldAccessKey
        case .secretKey: L10n.fieldSecretKey
        case .serviceAccountKey: L10n.fieldServiceAccountKey
        case .host: L10n.fieldHost
        case .port: L10n.fieldPort
        case .username: L10n.fieldUsername
        case .remotePath: L10n.fieldRemoteFolder
        case .password: L10n.fieldPassword
        case .keyFile: L10n.fieldPrivateKey
        case .trustedHosts: L10n.fieldTrustedHosts
        case .encryptionPassword: L10n.fieldEncryptionPassword
        case .confirmation: L10n.fieldConfirmPassword
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
    case sftp = "SFTP"
    case googleCloudStorage = "GCS"

    public var id: Self { self }

    public var backend: Backend {
        switch self {
        case .other, .aws, .cloudflare, .minio, .wasabi, .digitalOcean: .s3Compatible
        case .sftp: .sftp
        case .googleCloudStorage: .gcs
        }
    }

    public var title: String {
        switch self {
        case .other: L10n.providerS3Compatible
        case .aws: L10n.providerAmazonS3
        case .cloudflare: L10n.providerCloudflareR2
        case .minio: L10n.providerMinIO
        case .wasabi: L10n.providerWasabi
        case .digitalOcean: L10n.providerDigitalOceanSpaces
        case .sftp: L10n.providerSFTP
        case .googleCloudStorage: L10n.providerGoogleCloudStorage
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
    public var serviceAccountKey: String
    public var serviceAccountEmail: String? { ServiceAccountKey(json: serviceAccountKey)?.email }

    public init(
        accessKey: String = "", secretKey: String = "", sessionToken: String = "", encryptionPassword: String = "",
        password: String = "", keyPassphrase: String = "", serviceAccountKey: String = ""
    ) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.sessionToken = sessionToken
        self.encryptionPassword = encryptionPassword
        self.password = password
        self.keyPassphrase = keyPassphrase
        self.serviceAccountKey = serviceAccountKey
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
        serviceAccountKey = try container.decodeIfPresent(String.self, forKey: .serviceAccountKey) ?? ""
    }

    public func pruned(for connection: Connection) -> Credentials {
        var credentials = self
        switch connection.backend {
        case .s3Compatible:
            credentials.password = ""
            credentials.keyPassphrase = ""
            credentials.serviceAccountKey = ""
        case .sftp:
            credentials.accessKey = ""
            credentials.secretKey = ""
            credentials.sessionToken = ""
            credentials.serviceAccountKey = ""
            if connection.sftp.authentication != .password { credentials.password = "" }
            if connection.sftp.authentication != .privateKey { credentials.keyPassphrase = "" }
        case .gcs:
            credentials.accessKey = ""
            credentials.secretKey = ""
            credentials.sessionToken = ""
            credentials.password = ""
            credentials.keyPassphrase = ""
        }
        return credentials
    }

    public func validate(for connection: Connection) -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        switch connection.backend {
        case .s3Compatible:
            result.check(!accessKey.isBlank, field: .accessKey, message: L10n.accessKeyEmpty)
            result.check(!secretKey.isBlank, field: .secretKey, message: L10n.secretKeyEmpty)
        case .sftp:
            result.check(
                connection.sftp.authentication != .password || !password.isEmpty,
                field: .password, message: L10n.passwordEmpty
            )
        case .gcs:
            result.check(!serviceAccountKey.isBlank, field: .serviceAccountKey, message: L10n.importServiceAccountKey)
        }
        if connection.encrypted {
            result.check(!encryptionPassword.isBlank, field: .encryptionPassword, message: L10n.encryptionPasswordEmpty)
        }
        return result
    }
}

public struct AppError: LocalizedError, Sendable {
    public let errorDescription: String?
    public init(_ message: String) { errorDescription = message }
}

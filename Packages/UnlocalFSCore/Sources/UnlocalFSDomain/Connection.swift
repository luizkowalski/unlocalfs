import Foundation

public struct Connection: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var provider = Provider.other
    public var endpoint = ""
    public var region = "auto"
    public var bucket = ""
    public var folder = ""
    public var cacheLimit: Int64 = 1_000_000_000
    public var minimumFreeSpace: Int64 = 0
    public var bandwidthLimit: Int64 = 0
    public var transfers = 4
    public var connectsAutomatically = false
    public var readOnly = false
    public var prefersUploadTimes = false
    public var multiThreadUploads = false
    public var encrypted = false
    public var sftp = SFTPSettings()
    public var aws = AWSSettings()
    public var gcs = GCSSettings()

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
        prefersUploadTimes = try container.decodeIfPresent(Bool.self, forKey: .prefersUploadTimes) ?? prefersUploadTimes
        multiThreadUploads = try container.decodeIfPresent(Bool.self, forKey: .multiThreadUploads) ?? multiThreadUploads
        encrypted = try container.decodeIfPresent(Bool.self, forKey: .encrypted) ?? encrypted
        connectsAutomatically = try container.decodeIfPresent(Bool.self, forKey: .connectsAutomatically) ?? connectsAutomatically
        sftp = try container.decodeIfPresent(SFTPSettings.self, forKey: .sftp) ?? sftp
        aws = try container.decodeIfPresent(AWSSettings.self, forKey: .aws) ?? aws
        gcs = try container.decodeIfPresent(GCSSettings.self, forKey: .gcs) ?? GCSSettings(authentication: .serviceAccount)
    }

    public var backend: Backend { provider.backend }

    public var usesUploadTimes: Bool { backend.supportsUploadTimes && (readOnly || prefersUploadTimes) }

    public var usesGoogleSignIn: Bool {
        switch backend {
        case .googleDrive: true
        case .gcs: gcs.authentication == .googleAccount
        case .s3Compatible, .sftp: false
        }
    }

    public var exportsRcloneConfig: Bool { encrypted }

    public var shareLinkRefusal: String? {
        if !backend.supportsShareLinks { return String(localized: .linksUnavailable(provider.title)) }
        if encrypted { return String(localized: .linksUnavailableEncrypted) }
        return nil
    }

    public var versionsRefusal: String? {
        backend.supportsVersions ? nil : String(localized: .versionsUnavailable(provider.title))
    }

    public var versionRestoreRefusal: String? {
        versionsRefusal ?? serverCopyRefusal
    }

    public var serverCopyRefusal: String? {
        if !backend.supportsServerCopy { return String(localized: .serverCopyUnavailable(provider.title)) }
        if readOnly { return String(localized: .driveIsReadOnly) }
        return nil
    }

    public var bucketPath: String { folder.isEmpty ? bucket : "\(bucket)/\(folder)" }

    public var storageName: String {
        switch backend {
        case .s3Compatible, .gcs: bucket
        case .googleDrive: folder.isEmpty ? String(localized: .myDrive) : folder
        case .sftp: sftp.host
        }
    }

    public func shouldConnectAutomatically(status: MountStatus) -> Bool {
        connectsAutomatically && !status.isActive
    }

    private static let forbiddenNameCharacters = CharacterSet(charactersIn: "/:").union(.controlCharacters)

    public func validate() -> ValidationResult {
        var result = ValidationResult()
        result.check(!name.isBlank, field: .name, message: String(localized: .nameEmpty))
        result.check(
            name != "." && name != ".." && name.rangeOfCharacter(from: Self.forbiddenNameCharacters) == nil,
            field: .name, message: String(localized: .nameHasForbiddenCharacters),
        )
        result.check(name.utf8.count <= 120, field: .name, message: String(localized: .nameTooLong))
        switch backend {
        case .s3Compatible:
            result.issues += validateEndpoint().issues + validateBucket().issues
            if provider.hasAWSSettings { result.issues += aws.validate().issues }
        case .gcs: result.issues += validateBucket().issues
        case .googleDrive: result.issues += validateFolder().issues
        case .sftp: result.issues += sftp.validate().issues
        }
        return result
    }

    private func validateEndpoint() -> ValidationResult {
        var result = ValidationResult()
        let url = URL(string: endpoint)
        result.check(url?.scheme?.isEmpty == false && url?.host != nil, field: .endpoint, message: String(localized: .endpointInvalidURL))
        let validEndpoint = URLComponents(string: endpoint).map { url in
            ["http", "https"].contains(url.scheme) &&
                url.host?.isEmpty == false && url.user == nil && url.password == nil &&
                url.query == nil && url.fragment == nil && (url.path.isEmpty || url.path == "/")
        } ?? false
        result.check(
            validEndpoint, field: .endpoint,
            message: String(localized: .endpointNotDirect),
        )
        return result
    }

    private func validateBucket() -> ValidationResult {
        var result = ValidationResult()
        result.check(!bucket.isBlank, field: .bucket, message: String(localized: .bucketEmpty))
        result.check(
            bucket != "." && bucket != ".." &&
                bucket.rangeOfCharacter(from: Self.forbiddenNameCharacters.union(.whitespacesAndNewlines)) == nil,
            field: .bucket, message: String(localized: .bucketHasPath),
        )
        result.issues += validateFolder().issues
        return result
    }

    private func validateFolder() -> ValidationResult {
        var result = ValidationResult()
        result.check(
            (folder.isEmpty || folder.split(separator: "/", omittingEmptySubsequences: false).allSatisfy { !["", ".", ".."].contains($0) }) &&
                folder.rangeOfCharacter(from: .controlCharacters) == nil,
            field: .folder, message: String(localized: .folderPathInvalid),
        )
        return result
    }

    public func validate(against connections: [Connection]) -> ValidationResult {
        var result = validate()
        result.check(
            !connections.contains(where: { $0.id != id && $0.name.caseInsensitiveCompare(name) == .orderedSame }),
            field: .name, message: String(localized: .nameAlreadyExists),
        )
        return result
    }

    public func validate(credentials: Credentials, confirmation: String, against connections: [Connection]) -> ValidationResult {
        var result = validate(against: connections)
        result.issues += credentials.validate(for: self).issues
        if encrypted, !connections.contains(where: { $0.id == id }) {
            result.check(confirmation == credentials.encryptionPassword, field: .confirmation, message: String(localized: .passwordsDoNotMatch))
        }
        return result
    }
}

public enum ConnectionField: CaseIterable, Sendable {
    case name, endpoint, bucket, folder, accessKey, secretKey
    case serviceAccountKey, googleAccount
    case host, port, username, remotePath
    case password, keyFile
    case encryptionPassword, confirmation
    case kmsKey

    public var displayName: String {
        switch self {
        case .name: String(localized: .fieldName)
        case .endpoint: String(localized: .fieldEndpoint)
        case .bucket: String(localized: .fieldBucket)
        case .folder: String(localized: .fieldFolder)
        case .accessKey: String(localized: .fieldAccessKey)
        case .secretKey: String(localized: .fieldSecretKey)
        case .serviceAccountKey: String(localized: .fieldServiceAccountKey)
        case .googleAccount: String(localized: .fieldGoogleAccount)
        case .host: String(localized: .fieldHost)
        case .port: String(localized: .fieldPort)
        case .username: String(localized: .fieldUsername)
        case .remotePath: String(localized: .fieldRemoteFolder)
        case .password: String(localized: .password)
        case .keyFile: String(localized: .privateKey)
        case .encryptionPassword: String(localized: .fieldEncryptionPassword)
        case .confirmation: String(localized: .fieldConfirmPassword)
        case .kmsKey: String(localized: .fieldKMSKey)
        }
    }
}

public enum Provider: String, Codable, CaseIterable, Identifiable, Sendable {
    case aws = "AWS"
    case cloudflare = "Cloudflare"
    case digitalOcean = "DigitalOcean"
    case googleCloudStorage = "GCS"
    case googleDrive = "GoogleDrive"
    case minio = "Minio"
    case wasabi = "Wasabi"
    case other = "Other"
    case sftp = "SFTP"

    public var id: Self { self }

    public var group: ProviderGroup {
        switch self {
        case .aws, .cloudflare, .digitalOcean, .minio, .wasabi: .s3Services
        case .googleCloudStorage, .googleDrive: .google
        case .other, .sftp: .generic
        }
    }

    public var backend: Backend {
        switch self {
        case .other, .aws, .cloudflare, .minio, .wasabi, .digitalOcean: .s3Compatible
        case .sftp: .sftp
        case .googleCloudStorage: .gcs
        case .googleDrive: .googleDrive
        }
    }

    public var hasAWSSettings: Bool { self == .aws }

    public var title: String {
        switch self {
        case .other: String(localized: .providerS3Compatible)
        case .aws: String(localized: .providerAmazonS3)
        case .cloudflare: String(localized: .providerCloudflareR2)
        case .minio: String(localized: .providerMinIO)
        case .wasabi: String(localized: .providerWasabi)
        case .digitalOcean: String(localized: .providerDigitalOceanSpaces)
        case .sftp: String(localized: .providerSFTP)
        case .googleCloudStorage: String(localized: .providerGoogleCloudStorage)
        case .googleDrive: String(localized: .providerGoogleDrive)
        }
    }
}

public enum ProviderGroup: CaseIterable, Sendable {
    case s3Services, google, generic
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
    public var googleToken: String
    public var googleAccountID: String
    public var isSignedInToGoogle: Bool { GoogleToken(json: googleToken) != nil }

    public var googleSignIn: GoogleSignIn {
        get { GoogleSignIn(token: googleToken, accountID: googleAccountID) }
        set {
            googleToken = newValue.token
            googleAccountID = newValue.accountID
        }
    }

    public func requireSameGoogleAccount(as signIn: GoogleSignIn) throws {
        guard googleAccountID.isEmpty || googleAccountID == signIn.accountID else { throw GoogleAccountChanged() }
    }

    public var secrets: [String] {
        [
            accessKey, secretKey, sessionToken, encryptionPassword, obscuredEncryptionPassword,
            password, obscuredPassword, keyPassphrase, obscuredKeyPassphrase, serviceAccountKey, googleToken,
        ] + (GoogleToken(json: googleToken).map { [$0.accessToken, $0.refreshToken] } ?? [])
    }

    public init(
        accessKey: String = "", secretKey: String = "", sessionToken: String = "", encryptionPassword: String = "",
        password: String = "", keyPassphrase: String = "", serviceAccountKey: String = "", googleToken: String = "", googleAccountID: String = "",
    ) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.sessionToken = sessionToken
        self.encryptionPassword = encryptionPassword
        self.password = password
        self.keyPassphrase = keyPassphrase
        self.serviceAccountKey = serviceAccountKey
        self.googleToken = googleToken
        self.googleAccountID = googleAccountID
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
        googleToken = try container.decodeIfPresent(String.self, forKey: .googleToken) ?? ""
        googleAccountID = try container.decodeIfPresent(String.self, forKey: .googleAccountID) ?? ""
    }

    public func pruned(for connection: Connection) -> Credentials {
        var credentials = self
        switch connection.backend {
        case .s3Compatible:
            credentials.password = ""
            credentials.keyPassphrase = ""
            credentials.serviceAccountKey = ""
            credentials.googleSignIn = GoogleSignIn()
        case .sftp:
            credentials.accessKey = ""
            credentials.secretKey = ""
            credentials.sessionToken = ""
            credentials.serviceAccountKey = ""
            credentials.googleSignIn = GoogleSignIn()
            if connection.sftp.authentication != .password { credentials.password = "" }
            if connection.sftp.authentication != .privateKey { credentials.keyPassphrase = "" }
        case .gcs, .googleDrive:
            credentials.accessKey = ""
            credentials.secretKey = ""
            credentials.sessionToken = ""
            credentials.password = ""
            credentials.keyPassphrase = ""
            if connection.usesGoogleSignIn {
                credentials.serviceAccountKey = ""
            } else {
                credentials.googleSignIn = GoogleSignIn()
            }
        }
        return credentials
    }

    public func validate(for connection: Connection) -> ValidationResult {
        var result = ValidationResult()
        switch connection.backend {
        case .s3Compatible:
            result.check(!accessKey.isBlank, field: .accessKey, message: String(localized: .accessKeyEmpty))
            result.check(!secretKey.isBlank, field: .secretKey, message: String(localized: .secretKeyEmpty))
        case .sftp:
            result.check(
                connection.sftp.authentication != .password || !password.isEmpty,
                field: .password, message: String(localized: .passwordEmpty),
            )
        case .gcs, .googleDrive:
            if connection.usesGoogleSignIn {
                result.check(isSignedInToGoogle, field: .googleAccount, message: String(localized: .signInWithGoogleFirst))
            } else {
                result.check(!serviceAccountKey.isBlank, field: .serviceAccountKey, message: String(localized: .importServiceAccountKey))
            }
        }
        if connection.encrypted {
            result.check(!encryptionPassword.isBlank, field: .encryptionPassword, message: String(localized: .encryptionPasswordEmpty))
        }
        return result
    }
}

public struct AppError: LocalizedError, Sendable {
    public let errorDescription: String?
    public init(_ message: String) { errorDescription = message }
}

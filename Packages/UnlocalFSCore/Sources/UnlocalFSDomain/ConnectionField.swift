import Foundation

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

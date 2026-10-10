import Foundation

public enum S3StorageClass: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard = "STANDARD"
    case intelligentTiering = "INTELLIGENT_TIERING"
    case standardInfrequentAccess = "STANDARD_IA"
    case oneZoneInfrequentAccess = "ONEZONE_IA"
    case glacierInstantRetrieval = "GLACIER_IR"

    public var id: Self { self }

    public var title: String {
        switch self {
        case .standard: String(localized: .storageClassStandard)
        case .intelligentTiering: String(localized: .storageClassIntelligentTiering)
        case .standardInfrequentAccess: String(localized: .storageClassStandardIA)
        case .oneZoneInfrequentAccess: String(localized: .storageClassOneZoneIA)
        case .glacierInstantRetrieval: String(localized: .storageClassGlacierInstantRetrieval)
        }
    }
}

public enum ServerSideEncryption: String, Codable, CaseIterable, Identifiable, Sendable {
    case s3Managed = "AES256"
    case kms = "aws:kms"

    public var id: Self { self }

    public var title: String {
        switch self {
        case .s3Managed: String(localized: .encryptionS3Managed)
        case .kms: String(localized: .encryptionKMS)
        }
    }
}

public struct AWSSettings: Codable, Equatable, Sendable {
    public var storageClass = S3StorageClass.standard
    public var serverSideEncryption: ServerSideEncryption?
    public var kmsKeyID = ""

    public init() {}

    public func validate() -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        if serverSideEncryption == .kms, !kmsKeyID.isEmpty {
            result.check(Self.isKMSKey(kmsKeyID), field: .kmsKey, message: String(localized: .kmsKeyInvalid))
        }
        return result
    }

    private static func isKMSKey(_ key: String) -> Bool {
        key.rangeOfCharacter(from: .whitespacesAndNewlines) == nil &&
            (UUID(uuidString: key) != nil || ["mrk-", "alias/", "arn:"].contains { key.hasPrefix($0) })
    }
}

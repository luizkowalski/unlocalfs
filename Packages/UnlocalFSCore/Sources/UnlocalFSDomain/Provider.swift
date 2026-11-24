import Foundation

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

public enum Backend: Sendable {
    case s3Compatible, sftp, gcs

    public var supportsShareLinks: Bool {
        switch self {
        case .s3Compatible: true
        case .sftp, .gcs: false
        }
    }

    public var supportsServerCopy: Bool {
        switch self {
        case .s3Compatible, .gcs: true
        case .sftp: false
        }
    }

    public var supportsUploadCleanup: Bool { self == .s3Compatible }

    public var supportsUploadTimes: Bool { self == .s3Compatible }

    public var supportsMultiThreadUploads: Bool { self == .sftp }

    public var locksFolderAfterSave: Bool {
        switch self {
        case .s3Compatible, .gcs: false
        case .sftp: true
        }
    }
}

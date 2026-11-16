public enum Backend: Sendable {
    case s3Compatible, sftp, gcs, googleDrive

    public var supportsShareLinks: Bool {
        switch self {
        case .s3Compatible: true
        case .sftp, .gcs, .googleDrive: false
        }
    }

    public var supportsServerCopy: Bool {
        switch self {
        case .s3Compatible, .gcs, .googleDrive: true
        case .sftp: false
        }
    }

    public var supportsUploadCleanup: Bool { self == .s3Compatible }

    public var supportsUploadTimes: Bool { self == .s3Compatible }

    public var supportsMultiThreadUploads: Bool { self == .sftp }

    public var locksFolderAfterSave: Bool {
        switch self {
        case .s3Compatible, .gcs, .googleDrive: false
        case .sftp: true
        }
    }
}

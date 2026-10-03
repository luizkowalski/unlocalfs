public enum Backend: Sendable {
    case s3Compatible, sftp

    public var supportsShareLinks: Bool {
        switch self {
        case .s3Compatible: true
        case .sftp: false
        }
    }

    public var locksFolderAfterSave: Bool {
        switch self {
        case .s3Compatible: false
        case .sftp: true
        }
    }
}

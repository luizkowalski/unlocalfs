public enum DriveCondition: Equatable, Sendable {
    case checking
    case working
    case needsReconnect
    case needsAttention
    case offline
    case uploadFailed
    case uploading(count: Int)
    case connected
    case ejected
    case disconnected

    public init(_ status: MountStatus?, busy: Bool, error: String?, networkAvailable: Bool) {
        if busy {
            self = .working
            return
        }
        if status?.needsReconnect == true {
            self = .needsReconnect
            return
        }
        if error != nil {
            self = .needsAttention
            return
        }
        guard let status else {
            self = .checking
            return
        }
        if status.isActive, !networkAvailable {
            self = .offline
            return
        }
        if status.failedUploads > 0 {
            self = .uploadFailed
            return
        }
        if status.pendingUploads > 0 {
            self = .uploading(count: status.pendingUploads)
            return
        }
        if status.isMounted {
            self = .connected
            return
        }
        if status.isRunning {
            self = .ejected
            return
        }
        self = .disconnected
    }
}

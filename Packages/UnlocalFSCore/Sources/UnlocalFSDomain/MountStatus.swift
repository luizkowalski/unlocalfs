import Foundation

public struct UploadsPendingError: LocalizedError, Sendable {
    public init() {}

    public var errorDescription: String? {
        L10n.uploadsPending
    }
}

public struct MountStatus: Equatable, Sendable {
    public var isMounted = false
    public var isRunning = false
    public var pendingUploads = 0
    public var pendingBytes: Int64 = 0
    public var failedUploads = 0
    public var bytesCached: Int64 = 0
    public var controlError: String?
    public init() {}

    public var isActive: Bool { isMounted || isRunning || needsReconnect }
    public var needsReconnect: Bool { controlError != nil }

    public func requireSafeDisconnect() throws {
        guard failedUploads == 0 else {
            throw AppError(L10n.failedUploadsNeedRetry)
        }
        guard pendingUploads == 0 else { throw UploadsPendingError() }
    }
}

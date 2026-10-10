import Foundation

public struct DriveEjectError: Error, Sendable {
    public init() {}
}

public struct UploadsPendingError: LocalizedError, Sendable {
    public init() {}

    public var errorDescription: String? {
        String(localized: .uploadsInProgress)
    }
}

public struct MountStatus: Equatable, Sendable {
    public var isMounted = false
    public var isRunning = false
    public var pendingUploads = 0
    public var failedUploads = 0
    public var bytesCached: Int64 = 0
    public var controlError: String?
    public init() {}

    public var isActive: Bool { isMounted || isRunning || needsReconnect }
    public var needsReconnect: Bool { controlError != nil }

    public func requireSafeDisconnect() throws {
        guard failedUploads == 0 else {
            throw AppError(String(localized: .failedUploadsNeedRetry))
        }
        guard pendingUploads == 0 else { throw UploadsPendingError() }
    }
}

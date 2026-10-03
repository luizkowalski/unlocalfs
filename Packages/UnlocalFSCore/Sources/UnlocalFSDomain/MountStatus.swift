import Foundation

public struct UploadsPendingError: LocalizedError, Sendable {
    public init() {}

    public var errorDescription: String? {
        "Uploads are still in progress. Wait for them to finish before disconnecting."
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
            throw AppError("Some files could not upload and need a retry. Keep UnlocalFS running until uploads finish.")
        }
        guard pendingUploads == 0 else { throw UploadsPendingError() }
    }
}

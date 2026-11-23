import Foundation

public struct DriveEjectError: LocalizedError, Sendable {
    public init() {}

    public var errorDescription: String? {
        String(localized: .driveStillConnected)
    }
}

public struct UploadsPendingError: LocalizedError, Sendable {
    public init() {}

    public var errorDescription: String? {
        String(localized: .uploadsInProgress)
    }
}

public enum UploadState: String, Codable, Hashable, Sendable {
    case pending, failed
}

public struct MountStatus: Equatable, Sendable {
    public var isMounted = false
    public var isRunning = false
    public var uploads: [String: UploadState] = [:]
    public var uploadError: String?
    public var needsSignIn = false
    public var isDownloading = false
    public var uploadSpeed: Double = 0
    public var downloadSpeed: Double = 0
    public var bytesCached: Int64 = 0
    public var unsavedTraffic = Traffic()
    public var controlError: String?
    public init() {}

    public var pendingUploads: Int { uploads.count }
    public var failedUploads: Int { uploads.values.count { $0 == .failed } }
    public var isActive: Bool { isMounted || isRunning || needsReconnect }
    public var needsReconnect: Bool { controlError != nil }
    public var isServing: Bool { isRunning && !needsReconnect }

    public func requireSafeDisconnect() throws {
        guard failedUploads == 0 else {
            throw AppError(String(localized: .failedUploadsNeedRetry))
        }
        guard pendingUploads == 0 else { throw UploadsPendingError() }
    }
}

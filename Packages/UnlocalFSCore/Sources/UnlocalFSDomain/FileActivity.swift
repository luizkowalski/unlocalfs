import Foundation

public struct FileActivity: Identifiable, Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case queued, uploading, downloading
        case failed(nextAttempt: Date)
        case uploaded(Date), downloaded(Date)
    }

    public let path: String
    public let size: Int64
    public let state: State
    public let bytesTransferred: Int64?
    public let bytesPerSecond: Double?
    public let uploadError: String?

    public init(path: String, size: Int64, state: State, bytesTransferred: Int64?, bytesPerSecond: Double? = nil, uploadError: String? = nil) {
        self.path = path
        self.size = size
        self.state = state
        self.bytesTransferred = bytesTransferred
        self.bytesPerSecond = bytesPerSecond
        self.uploadError = uploadError
    }

    public var id: String {
        switch state {
        case .queued, .uploading, .failed, .uploaded: "upload:\(path)"
        case .downloading, .downloaded: "download:\(path)"
        }
    }
}

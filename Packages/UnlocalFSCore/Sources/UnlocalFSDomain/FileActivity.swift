import Foundation

public struct FileActivity: Identifiable, Equatable, Sendable {
    public enum State: Comparable, Sendable {
        case uploading, downloading, retrying, queued
    }

    public let path: String
    public let size: Int64
    public let state: State
    public let bytesTransferred: Int64?

    public init(path: String, size: Int64, state: State, bytesTransferred: Int64?) {
        self.path = path
        self.size = size
        self.state = state
        self.bytesTransferred = bytesTransferred
    }

    public var id: String { "\(state == .downloading ? "download" : "upload"):\(path)" }
}

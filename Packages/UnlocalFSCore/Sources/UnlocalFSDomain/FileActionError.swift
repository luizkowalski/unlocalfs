import Foundation

public struct FileActionError: LocalizedError, Sendable {
    public let file: URL
    public let errorDescription: String?

    public init(file: URL, message: String) {
        self.file = file
        errorDescription = message
    }
}

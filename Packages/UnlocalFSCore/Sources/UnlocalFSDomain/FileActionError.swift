import Foundation

public struct FileActionError: LocalizedError, Sendable {
    public let file: URL
    public let errorDescription: String?

    public init(file: URL, message: String) {
        self.file = file
        errorDescription = message
    }

    static func wrapping<Result>(_ file: URL, _ body: () async throws -> Result) async throws -> Result {
        do {
            return try await body()
        } catch {
            throw FileActionError(file: file, message: error.localizedDescription)
        }
    }
}

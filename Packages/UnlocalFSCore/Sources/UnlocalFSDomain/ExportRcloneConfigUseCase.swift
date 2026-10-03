import Foundation

public struct ExportRcloneConfigUseCase: Sendable {
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway

    public init(repository: any ConnectionRepository, drives: any DriveGateway) {
        self.repository = repository
        self.drives = drives
    }

    public func execute(_ connection: Connection, to destination: URL, includesSecrets: Bool) async throws {
        guard connection.encrypted else { throw AppError("Only encrypted drives can export an rclone config.") }
        let credentials = includesSecrets ? try repository.credentials(for: connection.id) : nil
        try await drives.exportRcloneConfig(connection, credentials: credentials, to: destination)
    }
}

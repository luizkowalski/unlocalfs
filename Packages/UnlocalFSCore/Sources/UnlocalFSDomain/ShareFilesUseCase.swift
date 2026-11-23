import Foundation

public struct ShareFilesUseCase: Sendable {
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway

    public init(repository: any ConnectionRepository, drives: any DriveGateway) {
        self.repository = repository
        self.drives = drives
    }

    public func execute(_ files: [URL], expiry: ShareLinkExpiry) async throws -> [URL] {
        let connections = try repository.all()
        var links: [URL] = []
        for file in files {
            try await links.append(FileActionError.wrapping(file) {
                let drive = try drives.drive(containing: file, among: connections)
                if let refusal = drive.connection.shareLinkRefusal { throw AppError(refusal) }
                return try await drives.shareLink(
                    for: drive.connection, path: drive.path, expiry: expiry, credentials: repository.credentials(for: drive.connection.id),
                )
            })
        }
        return links
    }
}

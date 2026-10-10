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
            do {
                guard let drive = drives.remoteFile(file, among: connections) else {
                    throw AppError(String(localized: .fileNotInDrive))
                }
                guard drive.connection.backend.supportsShareLinks else {
                    throw AppError(String(localized: .linksUnavailable(drive.connection.provider.title)))
                }
                guard !drive.connection.encrypted else {
                    throw AppError(String(localized: .linksUnavailableEncrypted))
                }
                let link = try await drives.shareLink(
                    for: drive.connection, path: drive.path, expiry: expiry, credentials: repository.credentials(for: drive.connection.id)
                )
                links.append(link)
            } catch {
                throw FileActionError(file: file, message: error.localizedDescription)
            }
        }
        return links
    }
}

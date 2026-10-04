import Foundation

public struct ShareFileError: LocalizedError, Sendable {
    public let file: URL
    public let errorDescription: String?

    public init(file: URL, message: String) {
        self.file = file
        errorDescription = message
    }
}

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
                    throw AppError(L10n.fileNotInDrive)
                }
                guard drive.connection.backend.supportsShareLinks else {
                    throw AppError(L10n.linksUnavailable(for: drive.connection.provider.title))
                }
                guard !drive.connection.encrypted else {
                    throw AppError(L10n.linksUnavailableEncrypted)
                }
                let link = try await drives.shareLink(
                    for: drive.connection, path: drive.path, expiry: expiry, credentials: repository.credentials(for: drive.connection.id)
                )
                links.append(link)
            } catch {
                throw ShareFileError(file: file, message: error.localizedDescription)
            }
        }
        return links
    }
}

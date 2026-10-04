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
                    throw AppError("The file is not in an UnlocalFS drive.")
                }
                guard drive.connection.backend.supportsShareLinks else {
                    throw AppError("Links aren't available for SFTP drives.")
                }
                guard !drive.connection.encrypted else {
                    throw AppError("Links aren't available for encrypted drives because they would point to encrypted data.")
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

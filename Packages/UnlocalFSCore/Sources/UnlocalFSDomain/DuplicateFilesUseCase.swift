import Foundation

public struct DuplicateFilesUseCase: Sendable {
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway

    public init(repository: any ConnectionRepository, drives: any DriveGateway) {
        self.repository = repository
        self.drives = drives
    }

    public func execute(_ files: [URL]) async throws -> [String] {
        let connections = try repository.all()
        var copies: [String] = []
        for file in files {
            do {
                guard let drive = drives.remoteFile(file, among: connections) else {
                    throw AppError(String(localized: .fileNotInDrive))
                }
                guard drive.connection.backend.supportsServerCopy else {
                    throw AppError(String(localized: .serverCopyUnavailable(drive.connection.provider.title)))
                }
                guard !drive.connection.readOnly else { throw AppError(String(localized: .driveIsReadOnly)) }
                copies.append(try await drives.duplicate(drive.path, in: drive.connection))
            } catch {
                throw FileActionError(file: file, message: error.localizedDescription)
            }
        }
        return copies
    }
}

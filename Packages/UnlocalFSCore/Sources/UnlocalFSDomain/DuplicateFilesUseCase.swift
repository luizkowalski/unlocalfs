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
        var selection: [(connection: Connection, path: String)] = []
        for file in files {
            selection.append(try await withFile(file) {
                guard let drive = drives.remoteFile(file, among: connections) else {
                    throw AppError(String(localized: .fileNotInDrive))
                }
                guard drive.connection.backend.supportsServerCopy else {
                    throw AppError(String(localized: .serverCopyUnavailable(drive.connection.provider.title)))
                }
                guard !drive.connection.readOnly else { throw AppError(String(localized: .driveIsReadOnly)) }
                return drive
            })
        }
        var copies: [String] = []
        for (file, drive) in zip(files, selection) {
            copies.append(try await withFile(file) { try await drives.duplicate(drive.path, in: drive.connection) })
        }
        return copies
    }

    private func withFile<Result>(_ file: URL, _ body: () async throws -> Result) async throws -> Result {
        do {
            return try await body()
        } catch {
            throw FileActionError(file: file, message: error.localizedDescription)
        }
    }
}

import Foundation

public struct SaveConnectionUseCase: Sendable {
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway

    public init(repository: any ConnectionRepository, drives: any DriveGateway) {
        self.repository = repository
        self.drives = drives
    }

    public func execute(_ connection: Connection, credentials: Credentials, confirmation: String = "") async throws -> [Connection] {
        let saved = try repository.all()
        try connection.validate(credentials: credentials, confirmation: confirmation, against: saved).requireValid()
        if let previous = saved.first(where: { $0.id == connection.id }) {
            try requireSameStorage(previous, connection, credentials: credentials)
        }
        let prepared = try await drives.prepareCredentials(credentials.pruned(for: connection))
        try repository.save(connection, credentials: prepared)
        return try repository.all()
    }

    private func requireSameStorage(_ previous: Connection, _ connection: Connection, credentials: Credentials) throws {
        let duplicate = AppError(String(localized: .duplicateChangesLockedAttributes))
        guard previous.backend == connection.backend else { throw duplicate }
        guard connection.backend.locksFolderAfterSave else { return }
        guard previous.encrypted == connection.encrypted, previous.folderPath == connection.folderPath else { throw duplicate }
        if previous.encrypted, try repository.credentials(for: previous.id).encryptionPassword != credentials.encryptionPassword {
            throw AppError(String(localized: .encryptionPasswordImmutable))
        }
    }
}

public struct DeleteConnectionUseCase: Sendable {
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway

    public init(repository: any ConnectionRepository, drives: any DriveGateway) {
        self.repository = repository
        self.drives = drives
    }

    public func execute(_ connection: Connection) async throws -> [Connection] {
        guard await !drives.status(connection).isActive else { throw AppError(String(localized: .disconnectBeforeDelete)) }
        try repository.delete(connection.id)
        drives.removeCache(connection)
        return try repository.all()
    }
}

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
        guard previous.isSFTP || connection.isSFTP else { return }
        guard previous.isSFTP == connection.isSFTP, previous.encrypted == connection.encrypted,
              previous.sftp.host == connection.sftp.host, previous.sftp.port == connection.sftp.port,
              previous.sftp.username == connection.sftp.username, previous.sftp.remotePath == connection.sftp.remotePath else {
            throw AppError("Duplicate this drive to change its protocol, server, account, folder, or encryption.")
        }
        if previous.encrypted, try repository.credentials(for: previous.id).encryptionPassword != credentials.encryptionPassword {
            throw AppError("You cannot change the encryption password of a saved drive. Duplicate the drive to use a new password.")
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
        guard await !drives.status(connection).isActive else { throw AppError("Disconnect this drive before deleting it.") }
        try repository.delete(connection.id)
        drives.removeCache(connection)
        return try repository.all()
    }
}

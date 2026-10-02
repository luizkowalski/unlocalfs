import Foundation

public struct SaveConnectionUseCase: Sendable {
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway

    public init(repository: any ConnectionRepository, drives: any DriveGateway) {
        self.repository = repository
        self.drives = drives
    }

    public func execute(_ connection: Connection, credentials: Credentials, confirmation: String = "") async throws -> [Connection] {
        try connection.validate(credentials: credentials, confirmation: confirmation, against: repository.all()).requireValid()
        let prepared = try await drives.prepareCredentials(credentials)
        try repository.save(connection, credentials: prepared)
        return try repository.all()
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

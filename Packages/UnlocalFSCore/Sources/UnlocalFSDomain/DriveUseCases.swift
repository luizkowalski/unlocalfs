import Foundation

public struct ConnectDriveUseCase: Sendable {
    public enum Outcome: Sendable { case connected, ejected, reconnected }
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway

    public init(repository: any ConnectionRepository, drives: any DriveGateway) {
        self.repository = repository
        self.drives = drives
    }

    public func execute(_ connection: Connection) async throws -> Outcome {
        let current = await drives.status(connection)
        if current.needsReconnect {
            try await drives.reconnect(connection, credentials: repository.credentials(for: connection.id))
            return .reconnected
        }
        if current.isActive { return current.isMounted ? .connected : .ejected }
        try await drives.mount(connection, credentials: repository.credentials(for: connection.id))
        return .connected
    }
}

public struct QuitUseCase: Sendable {
    private let drives: any DriveGateway

    public init(drives: any DriveGateway) { self.drives = drives }

    public func execute(connections: [Connection], operationInProgress: Bool) async throws {
        guard !operationInProgress else { throw AppError(String(localized: .waitBeforeQuitting)) }
        for connection in connections where await drives.status(connection).isActive {
            throw AppError(String(localized: .disconnectBeforeQuitting))
        }
    }
}

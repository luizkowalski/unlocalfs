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
    public enum Decision: Equatable, Sendable { case quit, disconnect, wait(String) }
    private let drives: any DriveGateway

    public init(drives: any DriveGateway) { self.drives = drives }

    public func execute(connections: [Connection], operationInProgress: Bool) async -> Decision {
        guard !operationInProgress else { return .wait(String(localized: .waitBeforeQuitting)) }
        for connection in connections where await drives.status(connection).isActive {
            return .disconnect
        }
        return .quit
    }

    public func disconnectAll(connections: [Connection]) async -> (connection: Connection, error: any Error)? {
        var failure: (connection: Connection, error: any Error)?
        for connection in connections where await drives.status(connection).isActive {
            do {
                try await drives.unmount(connection)
            } catch {
                failure = failure ?? (connection, error)
            }
        }
        return failure
    }
}

import Foundation

public struct ConnectDriveUseCase: Sendable {
    public enum Outcome: Sendable { case connected, ejected }
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
            return .connected
        }
        if current.isActive { return current.isMounted ? .connected : .ejected }
        try await drives.mount(connection, credentials: repository.credentials(for: connection.id))
        return .connected
    }
}

public struct SignInAgainUseCase: Sendable {
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway

    public init(repository: any ConnectionRepository, drives: any DriveGateway) {
        self.repository = repository
        self.drives = drives
    }

    public func execute(_ connection: Connection, signIn: GoogleSignIn) async throws {
        var credentials = try repository.credentials(for: connection.id)
        try credentials.requireSameGoogleAccount(as: signIn)
        credentials.googleSignIn = signIn
        try await drives.test(connection, credentials: credentials)
        try repository.save(connection, credentials: credentials)
        guard await drives.status(connection).isServing else { return }
        try await drives.applyGoogleSignIn(connection, credentials: credentials)
    }
}

public struct QuitUseCase: Sendable {
    public enum Decision: Equatable, Sendable { case quit, disconnect([Connection]), wait(String) }
    private let drives: any DriveGateway

    public init(drives: any DriveGateway) { self.drives = drives }

    public func execute(connections: [Connection], operationInProgress: Bool) async -> Decision {
        guard !operationInProgress else { return .wait(String(localized: .waitBeforeQuitting)) }
        var active: [Connection] = []
        for connection in connections where await drives.status(connection).isActive {
            active.append(connection)
        }
        return active.isEmpty ? .quit : .disconnect(active)
    }
}

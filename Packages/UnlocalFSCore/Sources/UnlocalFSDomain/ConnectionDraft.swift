import Foundation

public struct ConnectionDraft: Identifiable, Sendable {
    public var connection: Connection
    public let credentialsSource: UUID
    public var id: UUID { connection.id }
    public var isDuplicate: Bool { credentialsSource != connection.id }

    public init(connection: Connection) {
        self.connection = connection
        credentialsSource = connection.id
    }

    public init(duplicating connection: Connection) {
        self.connection = connection
        self.connection.id = UUID()
        self.connection.name = String(localized: .duplicateName(connection.name))
        credentialsSource = connection.id
    }
}

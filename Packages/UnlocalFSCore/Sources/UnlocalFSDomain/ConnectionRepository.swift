import Foundation

public protocol ConnectionRepository: Sendable {
    func all() throws -> [Connection]
    func credentials(for id: UUID) throws -> Credentials
    func save(_ connection: Connection, credentials: Credentials) throws
    func delete(_ id: UUID) throws
}

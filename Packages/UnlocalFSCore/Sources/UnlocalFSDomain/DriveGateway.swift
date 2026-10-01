import Foundation

public protocol DriveGateway: Sendable {
    func test(_ connection: Connection, credentials: Credentials) async throws
    func prepareCredentials(_ credentials: Credentials) async throws -> Credentials
    func mount(_ connection: Connection, credentials: Credentials) async throws
    func unmount(_ connection: Connection) async throws
    func reconnect(_ connection: Connection, credentials: Credentials) async throws
    func status(_ connection: Connection) async -> MountStatus
    func activity(_ connection: Connection) async throws -> [FileActivity]
    func refresh(_ connection: Connection) async throws
    func shareLink(for connection: Connection, path: String, expiry: ShareLinkExpiry, credentials: Credentials) async throws -> URL
    func remoteFile(_ file: URL, among connections: [Connection]) -> (connection: Connection, path: String)?
    func removeCache(_ connection: Connection)
}

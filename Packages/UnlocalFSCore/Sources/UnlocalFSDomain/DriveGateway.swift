import Foundation

public protocol DriveGateway: Sendable {
    func test(_ connection: Connection, credentials: Credentials) async throws
    func trustServer(_ challenge: ServerTrustChallenge) async throws
    func cancelServerTrust(_ challenge: ServerTrustChallenge) async
    func forgetServer(_ connection: Connection) async throws
    func prepareCredentials(_ credentials: Credentials) async throws -> Credentials
    func signInWithGoogle(for backend: Backend) async throws -> GoogleSignIn
    func stopSignIns() async
    func applyGoogleSignIn(_ connection: Connection, credentials: Credentials) async throws
    func mount(_ connection: Connection, credentials: Credentials) async throws
    func unmount(_ connection: Connection) async throws
    func reconnect(_ connection: Connection, credentials: Credentials) async throws
    func status(_ connection: Connection) async -> MountStatus
    func activity(_ connection: Connection) async throws -> [FileActivity]
    func refresh(_ connection: Connection) async throws
    func exportRcloneConfig(_ connection: Connection, credentials: Credentials?, to destination: URL) async throws
    func shareLink(for connection: Connection, path: String, expiry: ShareLinkExpiry, credentials: Credentials) async throws -> URL
    func duplicate(_ path: String, in connection: Connection) async throws -> String
    func deleteFileToStopUpload(_ path: String, in connection: Connection) async throws
    func unfinishedUploads(in connection: Connection) async throws -> [UnfinishedUpload]
    func removeAbandonedUploads(in connection: Connection) async throws
    func mountLocation(_ connection: Connection) -> URL
    func removeCache(_ connection: Connection) throws
}

public extension DriveGateway {
    func remoteFile(_ file: URL, among connections: [Connection]) -> (connection: Connection, path: String)? {
        for connection in connections {
            if let path = file.path(inside: mountLocation(connection)), !path.isEmpty { return (connection, path) }
        }
        return nil
    }

    func drive(containing file: URL, among connections: [Connection]) throws -> (connection: Connection, path: String) {
        guard !file.hasDirectoryPath else { throw AppError(String(localized: .foldersNotSupported)) }
        guard let drive = remoteFile(file, among: connections) else { throw AppError(String(localized: .fileNotInDrive)) }
        return drive
    }
}

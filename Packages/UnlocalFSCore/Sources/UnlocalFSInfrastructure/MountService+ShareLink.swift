import Foundation
import UnlocalFSDomain

public extension MountService {
    func shareLink(for connection: Connection, path: String, expiry: ShareLinkExpiry, credentials: Credentials) async throws -> URL {
        try requireServing(connection, otherwise: .reconnectForLinks)
        let uploading: Bool
        do {
            uploading = try await isWaitingToUpload(path, in: connection)
        } catch {
            throw AppError(String(localized: .reconnectToCheckUploads(error.localizedDescription)))
        }
        if uploading { throw AppError(String(localized: .fileStillUploading)) }
        let remote = try await remote(for: connection, credentials: credentials)
        let output: Data
        do {
            output = try await runRemoteCommand(["link", "\(connection.driveStorage)/\(path)", "--expire", expiry.rawValue, "--quiet"], remote: remote)
        } catch {
            throw AppError(String(localized: .couldNotCreateLinkUploading(error.localizedDescription)))
        }
        guard let link = URL(string: String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)),
              ["http", "https"].contains(link.scheme) else {
            throw AppError(String(localized: .couldNotCreateLink))
        }
        return link
    }
}

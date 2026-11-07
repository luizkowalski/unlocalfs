import Foundation
import UnlocalFSDomain

public extension MountService {
    func deleteFileToStopUpload(_ path: String, in connection: Connection) async throws {
        try requireServing(connection, otherwise: .reconnectToStopUpload)
        guard try await isWaitingToUpload(path, in: connection) else {
            throw AppError(String(localized: .uploadAlreadyFinished((path as NSString).lastPathComponent)))
        }
        try await remove(paths.mount(connection).appending(path: path))
    }

    @concurrent private nonisolated func remove(_ file: URL) async throws {
        try FileManager.default.removeItem(at: file)
    }
}

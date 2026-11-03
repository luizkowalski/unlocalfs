import Foundation
import UnlocalFSDomain

public extension MountService {
    func deleteFileToStopUpload(_ path: String, in connection: Connection) async throws {
        guard FileManager.default.fileExists(atPath: paths.socket(connection).path) else {
            throw AppError(String(localized: .reconnectToStopUpload))
        }
        guard try await control(UploadQueue.self, connection, "vfs/queue").queue.contains(where: { $0.name == path }) else {
            throw AppError(String(localized: .uploadAlreadyFinished((path as NSString).lastPathComponent)))
        }
        try await remove(paths.mount(connection).appending(path: path))
    }

    @concurrent private nonisolated func remove(_ file: URL) async throws {
        try FileManager.default.removeItem(at: file)
    }
}

import Foundation
import UnlocalFSDomain

public extension MountService {
    func hasServerCopy(of path: String, in connection: Connection) async throws -> Bool {
        let target = RcloneRemote(connection: connection, credentials: nil, knownHosts: paths.knownHosts).target
        return try await control(RemoteItem.self, connection, "operations/stat", ["fs": target, "remote": path]).item != nil
    }

    func cancelUpload(_ path: String, in connection: Connection) async throws {
        guard try await control(UploadQueue.self, connection, "vfs/queue").queue.contains(where: { $0.name == path }) else {
            throw AppError(String(localized: .uploadAlreadyFinished((path as NSString).lastPathComponent)))
        }
        try await remove(paths.mount(connection).appending(path: path))
    }

    @concurrent private nonisolated func remove(_ file: URL) async throws {
        try FileManager.default.removeItem(at: file)
    }
}

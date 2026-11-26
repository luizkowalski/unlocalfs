import Foundation
import UnlocalFSDomain

public extension MountService {
    func versioning(of connection: Connection) async -> BucketVersioning {
        let reply = try? await control(CommandResult.self, connection, "backend/command", ["command": "versioning", "fs": connection.driveStorage])
        return switch reply?.result {
        case "Enabled": .enabled
        case "Suspended": .suspended
        case "Unversioned": .off
        default: .unknown
        }
    }

    func versions(in folder: String, of connection: Connection) async throws -> [FileVersion] {
        let reply: Data
        do {
            reply = try await runJob(connection, "operations/list", [
                "fs": connection.versionsTarget, "remote": folder, "opt": ["noMimeType": true], "_config": ["UseServerModTime": true],
            ])
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw AppError(String(localized: .couldNotListVersions(error.localizedDescription)))
        }
        return try JSONDecoder().decode(VersionsList.self, from: reply).output.list
            .filter { !$0.isDir }
            .map { FileVersion(path: $0.path, size: $0.size, savedAt: $0.modTime) }
    }

    func restore(_ version: FileVersion, asCopy: Bool, in connection: Connection) async throws {
        if try await isWaitingToUpload(version.filePath, in: connection) {
            throw AppError(String(localized: .restoreFileStillUploading))
        }
        try await copyOnServer(version.path, to: version.filePath, asCopy: asCopy, on: connection.versionsTarget, in: connection)
    }

    func preview(_ version: FileVersion, in connection: Connection) async throws -> URL {
        let folder = paths.previews.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            _ = try await runJob(connection, "operations/copyfile", [
                "srcFs": connection.versionsTarget, "srcRemote": version.path, "dstFs": folder.path, "dstRemote": version.name,
            ])
        } catch {
            try? FileManager.default.removeItem(at: folder)
            throw error
        }
        return folder.appending(path: version.name)
    }

    nonisolated func discardPreview(_ file: URL) {
        try? FileManager.default.removeItem(at: file.deletingLastPathComponent())
    }
}

private struct VersionsList: Decodable {
    struct Output: Decodable {
        let list: [ListedObject]
    }

    let output: Output
}

private struct ListedObject: Decodable {
    let path: String
    let size: Int64
    let modTime: Date
    let isDir: Bool

    enum CodingKeys: String, CodingKey {
        case path = "Path", size = "Size", modTime = "ModTime", isDir = "IsDir"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        size = try container.decode(Int64.self, forKey: .size)
        modTime = try rcloneDate(container.decode(String.self, forKey: .modTime))
        isDir = try container.decode(Bool.self, forKey: .isDir)
    }
}

private struct CommandResult: Decodable {
    let result: String
}

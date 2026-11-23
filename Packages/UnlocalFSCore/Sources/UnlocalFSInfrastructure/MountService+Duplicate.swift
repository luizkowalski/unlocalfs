import Foundation
import UnlocalFSDomain

extension MountService {
    private static let copyGroup = "duplicate"

    public func duplicate(_ path: String, in connection: Connection) async throws -> String {
        try requireServing(connection, otherwise: .reconnectToDuplicate)
        if try await isWaitingToUpload(path, in: connection) {
            throw AppError(String(localized: .duplicateFileStillUploading))
        }
        let destination = try await reserveCopyPath(for: path, of: connection)
        try await copyOnServer(path, to: destination, on: connection.driveTarget, in: connection)
        return destination
    }

    func copyOnServer(_ source: String, to destination: String, on remote: String, in connection: Connection) async throws {
        reservedCopies[connection.id, default: []].insert(destination)
        defer { reservedCopies[connection.id]?.remove(destination) }
        try await runJob(connection, "operations/copyfile", [
            "srcFs": remote, "srcRemote": source, "dstFs": remote, "dstRemote": destination, "_group": Self.copyGroup,
        ])
        let folder = (destination as NSString).deletingLastPathComponent
        _ = try? await control(connection, "vfs/refresh", folder.isEmpty ? [:] : ["dir": folder])
        _ = try? await names(in: paths.mount(connection).appending(path: folder))
    }

    func requireNoCopies(_ connection: Connection, status: MountStatus) async throws {
        guard reservedCopies[connection.id, default: []].isEmpty else { throw AppError(String(localized: .copyInProgress)) }
        guard connection.backend.supportsServerCopy, status.isServing else { return }
        for id in try await control(JobList.self, connection, "job/list").runningIds {
            let job = try await control(JobStatus.self, connection, "job/status", ["jobid": "\(id)"])
            if job.group == Self.copyGroup, !job.finished { throw AppError(String(localized: .copyInProgress)) }
        }
    }

    func reserveCopyPath(for path: String, of connection: Connection) async throws -> String {
        let folder = (path as NSString).deletingLastPathComponent
        let target = connection.driveTarget
        let mounted = try await names(in: paths.mount(connection).appending(path: folder))
        let name = CopyName(of: (path as NSString).lastPathComponent)
        var attempt = 0
        while true {
            attempt += 1
            let fileName = name.attempt(attempt)
            let candidate = (folder as NSString).appendingPathComponent(fileName)
            guard !mounted.contains(fileName), !reservedCopies[connection.id, default: []].contains(candidate) else { continue }
            reservedCopies[connection.id, default: []].insert(candidate)
            var keep = false
            defer { if !keep { reservedCopies[connection.id]?.remove(candidate) } }
            keep = try await control(RemoteItem.self, connection, "operations/stat", ["fs": target, "remote": candidate]).item == nil
            if keep { return candidate }
        }
    }

    @concurrent nonisolated func names(in folder: URL) async throws -> Set<String> {
        try Set(FileManager.default.contentsOfDirectory(atPath: folder.path))
    }
}

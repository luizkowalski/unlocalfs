import Foundation
import UnlocalFSDomain

extension MountService {
    private static let copyGroup = "duplicate"

    public func duplicate(_ path: String, in connection: Connection) async throws -> String {
        guard isMounted(paths.mount(connection)), FileManager.default.fileExists(atPath: paths.socket(connection).path) else {
            throw AppError(String(localized: .reconnectToDuplicate))
        }
        copiesInFlight[connection.id, default: 0] += 1
        defer { copiesInFlight[connection.id]? -= 1 }
        if try await control(UploadQueue.self, connection, "vfs/queue").queue.contains(where: { $0.name == path }) {
            throw AppError(String(localized: .duplicateFileStillUploading))
        }
        let target = RcloneRemote(connection: connection, credentials: nil, knownHosts: paths.knownHosts).target
        let folder = (path as NSString).deletingLastPathComponent
        let destination = try await reserveCopyPath(for: path, in: folder, of: connection, target: target)
        defer { reservedCopies[connection.id]?.remove(destination) }
        let job = try await control(StartedJob.self, connection, "operations/copyfile", [
            "srcFs=\(target)", "srcRemote=\(path)", "dstFs=\(target)", "dstRemote=\(destination)",
            "_async=true", "_group=\(Self.copyGroup)"
        ])
        while true {
            let status = try await control(JobStatus.self, connection, "job/status", ["jobid=\(job.jobid)"])
            if status.finished {
                guard status.success else { throw AppError(status.error) }
                break
            }
            try await Task.sleep(for: .milliseconds(500))
        }
        _ = try? await control(connection, "vfs/refresh", folder.isEmpty ? [] : ["dir=\(folder)"])
        return destination
    }

    func requireNoCopies(_ connection: Connection, status: MountStatus) async throws {
        guard copiesInFlight[connection.id, default: 0] == 0 else { throw AppError(String(localized: .copyInProgress)) }
        guard connection.backend.supportsServerCopy, status.isRunning, !status.needsReconnect else { return }
        for id in try await control(JobList.self, connection, "job/list").runningIds {
            let job = try await control(JobStatus.self, connection, "job/status", ["jobid=\(id)"])
            if job.group == Self.copyGroup, !job.finished { throw AppError(String(localized: .copyInProgress)) }
        }
    }

    private func reserveCopyPath(for path: String, in folder: String, of connection: Connection, target: String) async throws -> String {
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
            keep = try await control(RemoteItem.self, connection, "operations/stat", ["fs=\(target)", "remote=\(candidate)"]).item == nil
            if keep { return candidate }
        }
    }

    @concurrent private nonisolated func names(in folder: URL) async throws -> Set<String> {
        Set(try FileManager.default.contentsOfDirectory(atPath: folder.path))
    }
}

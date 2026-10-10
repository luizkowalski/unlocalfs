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
        if try await activity(connection).contains(where: { $0.path == path && $0.state != .downloading }) {
            throw AppError(String(localized: .duplicateFileStillUploading))
        }
        let target = RcloneRemote(connection: connection, credentials: nil, knownHosts: paths.knownHosts).target
        let destination = try await freeCopyPath(for: path, in: connection, target: target)
        reservedCopies[connection.id, default: []].insert(destination)
        defer { reservedCopies[connection.id]?.remove(destination) }
        let job = try await JSONDecoder().decode(StartedJob.self, from: control(connection, "operations/copyfile", [
            "srcFs=\(target)", "srcRemote=\(path)", "dstFs=\(target)", "dstRemote=\(destination)",
            "_async=true", "_group=\(Self.copyGroup)"
        ]))
        while true {
            let status = try await JSONDecoder().decode(JobStatus.self, from: control(connection, "job/status", ["jobid=\(job.jobid)"]))
            if status.finished {
                guard status.success else { throw AppError(status.error) }
                break
            }
            try await Task.sleep(for: .milliseconds(500))
        }
        let folder = (destination as NSString).deletingLastPathComponent
        _ = try await control(connection, "vfs/refresh", folder.isEmpty ? [] : ["dir=\(folder)"])
        return destination
    }

    func requireNoCopies(_ connection: Connection, status: MountStatus) async throws {
        guard copiesInFlight[connection.id, default: 0] == 0 else { throw AppError(String(localized: .copyInProgress)) }
        guard status.isRunning, !status.needsReconnect else { return }
        guard let list = try? await control(connection, "job/list") else { return }
        let running = try JSONDecoder().decode(JobList.self, from: list).runningIds
        for id in running {
            let job = try await JSONDecoder().decode(JobStatus.self, from: control(connection, "job/status", ["jobid=\(id)"]))
            if job.group == Self.copyGroup, !job.finished { throw AppError(String(localized: .copyInProgress)) }
        }
    }

    private func freeCopyPath(for path: String, in connection: Connection, target: String) async throws -> String {
        let folder = (path as NSString).deletingLastPathComponent
        let mounted = Set(try FileManager.default.contentsOfDirectory(atPath: paths.mount(connection).appending(path: folder).path))
        let name = CopyName(of: (path as NSString).lastPathComponent)
        var attempt = 1
        while true {
            let candidate = (folder as NSString).appendingPathComponent(name.attempt(attempt))
            if !mounted.contains(name.attempt(attempt)), !reservedCopies[connection.id, default: []].contains(candidate) {
                let stat = try await control(connection, "operations/stat", ["fs=\(target)", "remote=\(candidate)"])
                if try JSONDecoder().decode(RemoteItem.self, from: stat).item == nil { return candidate }
            }
            attempt += 1
        }
    }
}

import Foundation
import UnlocalFSDomain

extension MountService {
    public func unfinishedUploads(in connection: Connection) async throws -> [UnfinishedUpload] {
        let reply = try await runBackendCommand("list-multipart-uploads", in: connection)
        return try JSONDecoder().decode(MultipartUploads.self, from: reply).uploads
    }

    public func removeAbandonedUploads(in connection: Connection) async throws {
        try await runBackendCommand("cleanup", in: connection, opt: #"{"max-age":"\#(Int(UnfinishedUpload.abandonedAge))s"}"#)
    }

    @discardableResult
    private func runBackendCommand(_ command: String, in connection: Connection, opt: String = "{}") async throws -> Data {
        let storage = RcloneRemote(connection: connection, credentials: nil, knownHosts: paths.knownHosts).storage
        let job = try await control(StartedJob.self, connection, "backend/command", ["command": command, "fs": storage, "opt": opt, "_async": "true"])
        return try await waitForJob(job, on: connection)
    }
}

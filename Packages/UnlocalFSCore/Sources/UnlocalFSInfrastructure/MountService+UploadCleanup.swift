import Foundation
import UnlocalFSDomain

public extension MountService {
    func unfinishedUploads(in connection: Connection) async throws -> [UnfinishedUpload] {
        let reply = try await runBackendCommand("list-multipart-uploads", in: connection)
        return try JSONDecoder().decode(MultipartUploads.self, from: reply).uploads
    }

    func removeAbandonedUploads(in connection: Connection) async throws {
        try await runBackendCommand("cleanup", in: connection, opt: #"{"max-age":"\#(Int(UnfinishedUpload.abandonedAge))s"}"#)
    }

    @discardableResult
    private func runBackendCommand(_ command: String, in connection: Connection, opt: String = "{}") async throws -> Data {
        let job = try await control(StartedJob.self, connection, "backend/command", ["command": command, "fs": connection.rcloneStorage, "opt": opt, "_async": "true"])
        return try await waitForJob(job, on: connection)
    }
}

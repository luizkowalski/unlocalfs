import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

extension MountTests {
    @Test func failingUploadsNeedAttentionAndBlockDisconnect() async throws {
        try await withDrive { drive in
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: drive.bucket.path)
            try Data("offline edit".utf8).write(to: drive.mounted.appendingPathComponent("upload.txt"))
            try await waitUntil { await drive.service.status(drive.connection).failedUploads > 0 }
            #expect(await drive.service.status(drive.connection).failedUploads == 1)
            await #expect(throws: AppError.self) { try await drive.service.unmount(drive.connection) }
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: drive.bucket.path)
            try await drive.waitForUploads(on: drive.service)
            try await drive.service.unmount(drive.connection)
        }
    }
}

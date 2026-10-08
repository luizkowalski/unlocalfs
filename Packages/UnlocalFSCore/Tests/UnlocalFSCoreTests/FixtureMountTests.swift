import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

extension IntegrationTests {
    @Test func cancellationUnmountsTheDriveAndStopsItsService() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: Drive.self)
        let task = Task {
            defer { continuation.finish() }
            try await withDrive { drive in
                try await drive.service.mount(drive.connection, credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
                continuation.yield(drive)
                try await Task.sleep(for: .seconds(3600))
            }
        }
        var iterator = stream.makeAsyncIterator()
        let drive = try #require(await iterator.next())
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        let status = await drive.service.status(drive.connection)
        #expect(!status.isMounted && !status.isRunning)
        try FileManager.default.removeItem(at: drive.paths.config.deletingLastPathComponent())
    }
}

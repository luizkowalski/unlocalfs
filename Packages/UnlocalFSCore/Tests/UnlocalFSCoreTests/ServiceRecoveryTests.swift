import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
import UnlocalFSTestSupport

@Suite struct ServiceRecoveryTests {
    @Test func aStatusErrorBlocksDisconnectWhileUploadsWait() async throws {
        let helper = try Process.run(URL(filePath: "/bin/sleep"), arguments: ["300"])
        defer { helper.terminate() }
        try await withControl { _, socket in
            try String(helper.processIdentifier).write(to: socket.appendingPathExtension("pid"), atomically: true, encoding: .utf8)
            return failingStatus(queue: queuedItem, helper: helper, socket: socket)
        } operation: { service, connection in
            let status = await service.status(connection)
            #expect(status.needsReconnect)
            #expect(status.controlError?.contains("core/stats failed") == true)
            await #expect(throws: UploadsPendingError.self) { try await service.unmount(connection) }
            #expect(helper.isRunning)
        }
    }

    @Test func aStatusErrorDoesNotBlockDisconnectWhenNoUploadsWait() async throws {
        let helper = try Process.run(URL(filePath: "/bin/sleep"), arguments: ["300"])
        defer { helper.terminate() }
        try await withControl { _, socket in
            try String(helper.processIdentifier).write(to: socket.appendingPathExtension("pid"), atomically: true, encoding: .utf8)
            return failingStatus(queue: "", helper: helper, socket: socket)
        } operation: { service, connection in
            try await service.unmount(connection)

            for _ in 0..<40 where helper.isRunning {
                try await Task.sleep(for: .milliseconds(50))
            }
            #expect(!helper.isRunning)
            #expect(await !service.status(connection).isActive)
        }
    }

    @Test func disconnectStopsAServiceThatCannotBeReached() async throws {
        let helper = try Process.run(URL(filePath: "/bin/sleep"), arguments: ["300"])
        defer { helper.terminate() }
        try await withFixture(script: "") { service, connection in
            try await String(helper.processIdentifier).write(to: service.paths.pidFile(connection), atomically: true, encoding: .utf8)
            #expect(await service.status(connection).needsReconnect)

            try await service.unmount(connection)

            for _ in 0..<40 where helper.isRunning {
                try await Task.sleep(for: .milliseconds(50))
            }
            #expect(!helper.isRunning)
            #expect(await !service.status(connection).isActive)
        }
    }

    @Test func aProcessThatReusedTheSavedPIDIsNotTheDriveService() async throws {
        let helper = try Process.run(URL(filePath: "/bin/sleep"), arguments: ["300"])
        defer { helper.terminate() }
        try await withFixture(script: "") { service, connection in
            let pidFile = await service.paths.pidFile(connection)
            try String(helper.processIdentifier).write(to: pidFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.modificationDate: Date.now.addingTimeInterval(-60)], ofItemAtPath: pidFile.path)

            #expect(await !service.status(connection).isActive)
            try await service.unmount(connection)
            #expect(helper.isRunning)
        }
    }
}

private func failingStatus(queue: String, helper: Process, socket: URL) -> ControlServer.Respond {
    { request in
        switch request.method {
        case "vfs/queue":
            return #"{"queue":[\#(queue)]}"#
        case "core/quit":
            helper.terminate()
            try FileManager.default.removeItem(at: socket)
            return "{}"
        default:
            return statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":42"#, stats: #"{"error":"core/stats failed","status":500}"#)
        }
    }
}

private let queuedItem = #"{"name":"a.txt","id":1,"size":1,"expiry":1,"tries":0,"delay":5,"uploading":false}"#

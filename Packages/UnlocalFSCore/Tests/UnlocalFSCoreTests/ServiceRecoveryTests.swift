import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
import UnlocalFSTestSupport

struct ServiceRecoveryTests {
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

            for _ in 0 ..< 40 where helper.isRunning {
                try await Task.sleep(for: .milliseconds(50))
            }
            #expect(!helper.isRunning)
            #expect(await !service.status(connection).isActive)
        }
    }

    @Test func aDriveEjectedInFinderStopsItsService() async throws {
        let helper = try Process.run(URL(filePath: "/bin/sleep"), arguments: ["300"])
        defer { helper.terminate() }
        try await withControl { _, socket in
            try String(helper.processIdentifier).write(to: socket.appendingPathExtension("pid"), atomically: true, encoding: .utf8)
            return { request in
                switch request.method {
                case "mount/listmounts":
                    return #"{"mountPoints":[]}"#
                case "core/quit":
                    helper.terminate()
                    try FileManager.default.removeItem(at: socket)
                    return "{}"
                default:
                    return statusBatch()
                }
            }
        } operation: { service, connection in
            #expect(await !service.status(connection).isActive)
            #expect(!helper.isRunning)
        }
    }

    @Test func disconnectStopsAServiceThatCannotBeReached() async throws {
        let helper = try Process.run(URL(filePath: "/bin/sleep"), arguments: ["300"])
        defer { helper.terminate() }
        try await withFixture(script: "") { service, connection in
            try await String(helper.processIdentifier).write(to: service.paths.pidFile(connection), atomically: true, encoding: .utf8)
            #expect(await service.status(connection).needsReconnect)

            try await service.unmount(connection)

            for _ in 0 ..< 40 where helper.isRunning {
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

extension ServiceRecoveryTests {
    @Test func signingInAgainRestoresUploadsOnTheConnectedDrive() async throws {
        try await withRevokedDrive { useCase, repository, drives, connection in
            #expect(await drives.service.status(connection).needsSignIn)

            try await useCase.execute(connection, token: newTokenJSON)

            #expect(try repository.credentials(for: connection.id).googleToken == newTokenJSON)
            #expect(!controlCalls(drives).contains("core/quit"))
            let update = try JSONSerialization.jsonObject(with: Data(contentsOf: drives.root.appending(path: "updated"))) as? [String: Any]
            #expect(update?["name"] as? String == "unlocalfs-gcs")
            #expect((update?["parameters"] as? [String: String])?["token"] == newTokenJSON)
            let status = await drives.service.status(connection)
            #expect(status.isServing && status.failedUploads == 0 && !status.needsSignIn)
            #expect(drives.rcloneCalls == ["lsf"])
        }
    }

    @Test func signInThatFailsTheConnectionTestChangesNothing() async throws {
        try await withRevokedDrive { useCase, repository, drives, connection in
            FileManager.default.createFile(atPath: drives.root.appending(path: "lsf-fails").path, contents: Data())

            await #expect(throws: AppError.self) { try await useCase.execute(connection, token: newTokenJSON) }

            let saved = try repository.credentials(for: connection.id)
            #expect(saved == Credentials.google())
            #expect(controlCalls(drives).isEmpty)
        }
    }

    @Test func signInThatCannotBeSavedIsNotSentToTheDrive() async throws {
        let storage = LockableCredentialStorage()
        try await withRevokedDrive(storage: storage) { useCase, repository, drives, connection in
            storage.lock()

            await #expect(throws: AppError.self) { try await useCase.execute(connection, token: newTokenJSON) }

            let saved = try repository.credentials(for: connection.id)
            #expect(saved == Credentials.google())
            #expect(controlCalls(drives).isEmpty)
        }
    }

    @Test func signInThatTheDriveRejectsStaysSavedAndKeepsTheDriveConnected() async throws {
        try await withRevokedDrive { useCase, repository, drives, connection in
            FileManager.default.createFile(atPath: drives.root.appending(path: "update-fails").path, contents: Data())

            await #expect(throws: AppError.self) { try await useCase.execute(connection, token: newTokenJSON) }

            let saved = try repository.credentials(for: connection.id)
            #expect(saved.googleToken == newTokenJSON)
            await #expect(throws: AppError.self) { try await drives.service.unmount(connection) }
            #expect(await drives.service.status(connection).failedUploads == 1)
        }
    }
}

private func withRevokedDrive(
    serving: Bool = true, storage: any CredentialStorage = MemoryCredentialStorage(),
    operation: (SignInAgainUseCase, SavedConnectionRepository, StubbedDrives, Connection) async throws -> Void,
) async throws {
    let drives = try StubbedDrives("sign-in") { root in
        """
        if [ "$1" = 'lsf' ] && [ -f '\(root.path)/lsf-fails' ]; then
            echo 'googleapi: Error 403: me@example.com does not have storage.objects.list access' >&2
            exit 1
        fi
        """
    }
    defer { drives.remove() }
    let connection = Connection.gcs(authentication: .googleAccount)
    let repository = SavedConnectionRepository(store: ConnectionStore(url: drives.paths.config), credentials: storage)
    try repository.save(connection, credentials: Credentials.google())
    let server = serving ? try ControlServer(at: drives.paths.socket(connection), respond: revokedDrive(drives.root)) : nil
    defer { server?.stop() }
    try await operation(SignInAgainUseCase(repository: repository, drives: drives.service), repository, drives, connection)
}

private func revokedDrive(_ root: URL) -> ControlServer.Respond {
    { request in
        let fileManager = FileManager.default
        let log = root.appending(path: "control-calls")
        if !fileManager.fileExists(atPath: log.path) { fileManager.createFile(atPath: log.path, contents: Data()) }
        let handle = try FileHandle(forWritingTo: log)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("\(request.method)\n".utf8))
        try handle.close()
        let retried = fileManager.fileExists(atPath: root.appending(path: "retried").path)
        let queue = retried ? #"{"queue":[]}"# : #"{"queue":[{"name":"a.txt","id":7,"size":1,"expiry":9,"tries":2,"delay":20,"uploading":false}]}"#
        switch request.method {
        case "config/update":
            if fileManager.fileExists(atPath: root.appending(path: "update-fails").path) { throw ControlFailure("update failed") }
            try request.body.write(to: root.appending(path: "updated"))
            return #"{"State":""}"#
        case "vfs/queue":
            return queue
        case "vfs/queue-set-expiry":
            let update = try? JSONSerialization.jsonObject(with: Data(contentsOf: root.appending(path: "updated"))) as? [String: Any]
            let token = (update?["parameters"] as? [String: String])?["token"] ?? ""
            let expiry = try JSONSerialization.jsonObject(with: request.body) as? [String: String]
            if token.contains("1//new-refresh"), expiry == ["id": "7", "expiry": "0"] {
                fileManager.createFile(atPath: root.appending(path: "retried").path, contents: Data())
            }
            return "{}"
        default:
            let error = retried ? "" : #","lastError":"\#(revokedGrantError)""#
            return statusBatch(queue: queue, stats: #"{\#(rcloneCounters)\#(error)}"#)
        }
    }
}

private func controlCalls(_ drives: StubbedDrives) -> [String] {
    let calls = (try? String(contentsOf: drives.root.appending(path: "control-calls"), encoding: .utf8)) ?? ""
    return calls.split(separator: "\n").map(String.init).filter { $0 != "job/batch" }
}

private final class LockableCredentialStorage: CredentialStorage {
    private let storage = MemoryCredentialStorage()
    private let locked = Mutex(false)

    func lock() { locked.withLock { $0 = true } }
    func read(_ id: UUID) throws -> Credentials? { try storage.read(id) }
    func save(_ credentials: Credentials, for id: UUID) throws {
        if locked.withLock({ $0 }) { throw AppError("Keychain locked") }
        try storage.save(credentials, for: id)
    }

    func delete(_ id: UUID) throws { try storage.delete(id) }
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
            return statusBatch(cache: #""bytesUsed":42"#, stats: #"{"error":"core/stats failed","status":500}"#)
        }
    }
}

private let queuedItem = #"{"name":"a.txt","id":1,"size":1,"expiry":1,"tries":0,"delay":5,"uploading":false}"#

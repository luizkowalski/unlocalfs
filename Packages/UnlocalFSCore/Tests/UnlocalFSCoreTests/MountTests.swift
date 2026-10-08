import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

enum ControlFault {
    case missingSocket, staleSocket, killedService
}

extension IntegrationTests {
    @Suite
    struct MountTests {
        @Test func s3DriveReadsUploadsSurvivesReopeningAndUnmountsSafely() async throws {
            try await withDrive { drive in
                try Data("hello from S3".utf8).write(
                    to: drive.bucket.appendingPathComponent("hello.txt"))
                try await drive.service.test(drive.connection, credentials: s3Credentials)
                await #expect(throws: AppError.self) {
                    try await drive.service.test(
                        drive.connection,
                        credentials: Credentials(accessKey: "test-key", secretKey: "wrong"))
                }
                try await drive.service.mount(drive.connection, credentials: s3Credentials)
                #expect(
                    try String(
                        contentsOf: drive.mounted.appendingPathComponent("hello.txt"), encoding: .utf8)
                        == "hello from S3")
                try Data("written through Finder's filesystem".utf8).write(
                    to: drive.mounted.appendingPathComponent("upload.txt"))
                #expect(await drive.service.status(drive.connection).pendingUploads > 0)
                let activity = try await drive.service.activity(drive.connection)
                #expect(activity.contains { $0.path == "upload.txt" && $0.state == .queued })
                await #expect(throws: UploadsPendingError.self) {
                    try await drive.service.unmount(drive.connection)
                }
                await #expect(throws: UploadsPendingError.self) {
                    try await drive.service.reconnect(drive.connection, credentials: s3Credentials)
                }
                let reopened = drive.reopen()
                #expect(await reopened.status(drive.connection).isMounted)
                try await drive.waitForUploads(on: reopened)
                #expect(
                    try String(
                        contentsOf: drive.bucket.appendingPathComponent("upload.txt"), encoding: .utf8)
                        == "written through Finder's filesystem")
                try FileManager.default.createDirectory(
                    at: drive.mounted.appendingPathComponent("empty folder"), withIntermediateDirectories: false)
                try await drive.waitForUploads(on: reopened)
                #expect(FileManager.default.fileExists(atPath: drive.bucket.appendingPathComponent("empty folder").path))
                #expect(try await reopened.activity(drive.connection).isEmpty)
                try await verifyUploadProgress(drive, service: reopened)
                try await reopened.unmount(drive.connection)
                let stopped = await reopened.status(drive.connection)
                #expect(!stopped.isMounted && !stopped.isRunning)
            }
        }

        @Test(arguments: [
            (ControlFault.missingSocket, false), (.missingSocket, true), (.staleSocket, false), (.staleSocket, true), (.killedService, false)
        ])
        func reconnectPreservesCachedFilesWhenControlIsLost(fault: ControlFault, reopened: Bool) async throws {
            try await withDrive { drive in
                try Data("remote file".utf8).write(to: drive.bucket.appendingPathComponent("hello.txt"))
                try await drive.service.mount(drive.connection, credentials: s3Credentials)
                #expect(try String(contentsOf: drive.mounted.appendingPathComponent("hello.txt"), encoding: .utf8) == "remote file")
                let diskCache = try #require(try await drive.control("vfs/stats")["diskCache"] as? [String: Any])
                let cached = URL(filePath: try #require(diskCache["path"] as? String)).appendingPathComponent("hello.txt")
                #expect(try String(contentsOf: cached, encoding: .utf8) == "remote file")
                let service = reopened ? drive.reopen() : drive.service
                let socket = drive.paths.socket(drive.connection)
                let hiddenSocket = socket.appendingPathExtension("hidden")
                defer {
                    if !FileManager.default.fileExists(atPath: socket.path) {
                        try? FileManager.default.moveItem(at: hiddenSocket, to: socket)
                    }
                }
                switch fault {
                case .missingSocket, .staleSocket:
                    try FileManager.default.moveItem(at: socket, to: hiddenSocket)
                    if fault == .staleSocket { FileManager.default.createFile(atPath: socket.path, contents: Data()) }
                case .killedService:
                    let pid = try #require(try await drive.control("core/pid")["pid"] as? Int)
                    _ = try await Command.run(URL(filePath: "/bin/kill"), ["-KILL", "\(pid)"])
                }
                try await waitUntil { await service.status(drive.connection).needsReconnect }
                #expect(await service.status(drive.connection).isMounted)
                try await service.reconnect(drive.connection, credentials: s3Credentials)
                let recovered = await service.status(drive.connection)
                #expect(recovered.isMounted)
                #expect(!recovered.needsReconnect)
                #expect(try String(contentsOf: cached, encoding: .utf8) == "remote file")
                #expect(try String(contentsOf: drive.mounted.appendingPathComponent("hello.txt"), encoding: .utf8) == "remote file")
                try await service.unmount(drive.connection)
                #expect(await !service.status(drive.connection).isActive)
            }
        }

        @Test func readOnlyFolderDriveShowsOnlyThatFolderAndAppliesItsLimits() async throws {
            var connection = fixture(folder: "clients/acme")
            connection.bandwidthLimit = 10_000_000
            connection.transfers = 8
            connection.cacheLimit = 512 << 20
            connection.minimumFreeSpace = 5 << 30
            try await withDrive(readOnly: true, connection: connection) { drive in
                let folder = drive.bucket.appendingPathComponent("clients/acme")
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try Data("acme plan".utf8).write(to: folder.appendingPathComponent("plan.txt"))
                try Data("other client".utf8).write(to: drive.bucket.appendingPathComponent("clients/other.txt"))
                try await drive.service.mount(drive.connection, credentials: s3Credentials)
                #expect(try FileManager.default.contentsOfDirectory(atPath: drive.mounted.path) == ["plan.txt"])
                #expect(try String(contentsOf: drive.mounted.appendingPathComponent("plan.txt"), encoding: .utf8) == "acme plan")
                #expect(throws: (any Error).self) {
                    try Data("nope".utf8).write(to: drive.mounted.appendingPathComponent("upload.txt"))
                }
                #expect(throws: (any Error).self) {
                    try FileManager.default.removeItem(at: drive.mounted.appendingPathComponent("plan.txt"))
                }
                let options = try await drive.control("options/get")
                let main = try #require(options["main"] as? [String: Any])
                #expect(main["BwLimit"] as? String == "9.537Mi")
                #expect(main["Transfers"] as? Int64 == 8)
                let vfs = try #require(options["vfs"] as? [String: Any])
                #expect(vfs["CacheMaxSize"] as? Int64 == 512 << 20)
                #expect(vfs["CacheMinFreeSpace"] as? Int64 == 5 << 30)
                #expect((vfs["CacheMaxAge"] as? NSNumber)?.doubleValue == Double(Int64.max))
                #expect(vfs["CacheMode"] as? String == "full")
                try await drive.service.unmount(drive.connection)
                #expect(FileManager.default.fileExists(atPath: folder.appendingPathComponent("plan.txt").path))
                #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent("upload.txt").path))
            }
        }

        @Test func encryptedDriveUploadsOnlyCiphertextAndRejectsTheWrongPassword() async throws {
            try await withDrive(encrypted: true) { drive in
                let credentials = try await drive.service.prepareCredentials(
                    Credentials(
                        accessKey: "test-key", secretKey: "test-secret",
                        encryptionPassword: "correct horse")
                )
                try await drive.service.mount(drive.connection, credentials: credentials)
                try Data("top secret".utf8).write(
                    to: drive.mounted.appendingPathComponent("secret plan.txt"))
                try await drive.waitForUploads(on: drive.service)
                let stored = try FileManager.default.subpathsOfDirectory(atPath: drive.bucket.path)
                let object = try #require(stored.first)
                #expect(stored.count == 1)
                #expect(!object.contains("secret"))
                #expect(
                    try !String(
                        decoding: Data(contentsOf: drive.bucket.appendingPathComponent(object)),
                        as: UTF8.self
                    ).contains("top secret"))
                try await drive.service.unmount(drive.connection)
                let reopened = drive.reopen()
                let savedCredentials = try JSONDecoder().decode(
                    Credentials.self, from: JSONEncoder().encode(credentials))
                try await reopened.mount(drive.connection, credentials: savedCredentials)
                #expect(await reopened.status(drive.connection).bytesCached == 10)
                try await reopened.unmount(drive.connection)
                try FileManager.default.removeItem(at: drive.paths.cache(drive.connection))
                try await drive.service.mount(drive.connection, credentials: credentials)
                #expect(
                    try String(
                        contentsOf: drive.mounted.appendingPathComponent("secret plan.txt"),
                        encoding: .utf8) == "top secret")
                try await drive.service.unmount(drive.connection)
                var wrong = credentials
                wrong.encryptionPassword = "wrong"
                await #expect {
                    try await drive.service.test(drive.connection, credentials: wrong)
                } throws: { $0.localizedDescription.contains("undecryptable") }
                await #expect {
                    try await drive.service.mount(drive.connection, credentials: wrong)
                } throws: { $0.localizedDescription.contains("undecryptable") }
                #expect(await !drive.service.status(drive.connection).isActive)
            }
        }
    }
}

let s3Credentials = Credentials(accessKey: "test-key", secretKey: "test-secret")

let helpers = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .appendingPathComponent("../../../../libexec").standardized

let rcloneExecutable = Task {
    let script = helpers.deletingLastPathComponent().appending(path: "scripts/fetch-rclone.sh")
    let output = try await Command.run(script, [])
    return URL(fileURLWithPath: String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
}

struct Drive: Sendable {
    let executable: URL
    let bucket: URL
    let paths: AppPaths
    let service: MountService
    let connection: Connection

    var mounted: URL { paths.mount(connection) }

    func reopen() -> MountService {
        MountService(executable: executable, helperDirectory: helpers, paths: paths)
    }

    func service(environment: [String: String]) -> MountService {
        MountService(executable: executable, helperDirectory: helpers, paths: paths, environment: environment)
    }

    func control(_ method: String, _ parameters: String...) async throws -> [String: Any] {
        let data = try await Command.run(
            executable,
            ["rc", "--unix-socket", paths.socket(connection).path, method] + parameters + [
                "--config", "/dev/null"
            ])
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func waitForUploads(on service: MountService) async throws {
        try await waitUntil(timeout: .seconds(20)) {
            let queue = try? await control("vfs/queue")["queue"] as? [[String: Any]]
            for item in (queue ?? []).compactMap({ $0["id"] as? Int }) {
                _ = try? await control("vfs/queue-set-expiry", "id=\(item)", "expiry=-60", "relative=true")
            }
            return await service.status(connection).pendingUploads == 0
        }
    }

    func disconnect() async throws {
        let savedPID = try? String(contentsOf: paths.pidFile(connection), encoding: .utf8)
        let pid = savedPID.flatMap { pid_t($0) }
        if await service.status(connection).isActive {
            try? await waitForUploads(on: service)
            try? await service.unmount(connection)
        }
        if await service.status(connection).isMounted {
            _ = try? await Command.run(URL(filePath: "/sbin/umount"), ["-f", mounted.path], timeout: .seconds(10))
        }
        if let pid, kill(pid, 0) == 0 {
            kill(pid, SIGKILL)
            try await waitUntil(timeout: .seconds(5)) { kill(pid, 0) != 0 && errno == ESRCH }
        }
        try await waitUntil(timeout: .seconds(5)) {
            let status = await service.status(connection)
            return !status.isMounted && !status.isRunning
        }
    }

}

func withDrive(
    folder: String = "", encrypted: Bool = false, readOnly: Bool = false, connection: Connection? = nil,
    _ body: (Drive) async throws -> Void
) async throws {
    let executable = try await rcloneExecutable.value
    try await withFixture { resources in
        let bucket = resources.root.appending(path: "source/my-bucket")
        try FileManager.default.createDirectory(at: bucket, withIntermediateDirectories: true)
        let server = try await S3Server(executable: executable, resources: resources)
        var connection = connection ?? fixture(folder: folder)
        connection.endpoint = server.endpoint
        connection.encrypted = encrypted
        connection.readOnly = readOnly
        let drive = await makeDrive(executable: executable, bucket: bucket, resources: resources, connection: connection)
        try await body(drive)
    }
}

private func verifyUploadProgress(_ drive: Drive, service: MountService) async throws {
    _ = try await drive.control("core/bwlimit", "rate=1M")
    try Data(repeating: 42, count: 8 * 1024 * 1024).write(
        to: drive.mounted.appendingPathComponent("large.bin"))
    try await waitUntil(timeout: .seconds(20)) {
        try await service.activity(drive.connection).contains {
            $0.path == "large.bin" && $0.state == .uploading && ($0.bytesTransferred ?? 0) > 0
                && $0.size == 8 * 1024 * 1024
        }
    }
    try await waitUntil(timeout: .seconds(20)) { try await service.activity(drive.connection).isEmpty }
    #expect(try await service.activity(drive.connection).isEmpty)
    #expect(await service.status(drive.connection).isMounted)
}

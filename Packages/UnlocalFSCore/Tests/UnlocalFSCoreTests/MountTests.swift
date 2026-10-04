import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite(
    .serialized,
    .enabled(
        if: ProcessInfo.processInfo.environment["RCLONE_BINARY"] != nil, "Set RCLONE_BINARY to run")
)
struct MountTests {
    @Test func s3DriveReadsUploadsSurvivesReopeningAndUnmountsSafely() async throws {
        try await withDrive { drive in
            try Data("hello from S3".utf8).write(
                to: drive.bucket.appendingPathComponent("hello.txt"))
            let credentials = Credentials(accessKey: "test-key", secretKey: "test-secret")
            try await drive.service.test(drive.connection, credentials: credentials)
            await #expect(throws: AppError.self) {
                try await drive.service.test(
                    drive.connection,
                    credentials: Credentials(accessKey: "test-key", secretKey: "wrong"))
            }
            try await drive.service.mount(drive.connection, credentials: credentials)
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
                try await drive.service.reconnect(drive.connection, credentials: credentials)
            }
            let reopened = drive.reopen()
            #expect(await reopened.status(drive.connection).isMounted)
            try await drive.waitForUploads(on: reopened)
            #expect(
                try String(
                    contentsOf: drive.bucket.appendingPathComponent("upload.txt"), encoding: .utf8)
                    == "written through Finder's filesystem")
            #expect(try await reopened.activity(drive.connection).isEmpty)
            try await verifyUploadProgress(drive, service: reopened)
            try await reopened.unmount(drive.connection)
            let stopped = await reopened.status(drive.connection)
            #expect(!stopped.isMounted && !stopped.isRunning)
        }
    }

    @Test func folderDriveShowsOnlyThatFolder() async throws {
        try await withDrive(folder: "clients/acme") { drive in
            let folder = drive.bucket.appendingPathComponent("clients/acme")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try Data("acme plan".utf8).write(to: folder.appendingPathComponent("plan.txt"))
            try Data("other client".utf8).write(
                to: drive.bucket.appendingPathComponent("clients/other.txt"))
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            #expect(
                try FileManager.default.contentsOfDirectory(atPath: drive.mounted.path) == [
                    "plan.txt"
                ])
            #expect(
                try String(
                    contentsOf: drive.mounted.appendingPathComponent("plan.txt"), encoding: .utf8)
                    == "acme plan")
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test func mountingRotatesAnOversizedLog() async throws {
        try await withDrive { drive in
            try drive.paths.prepare()
            let log = drive.paths.log(drive.connection)
            try Data(repeating: 120, count: 6 * 1024 * 1024).write(to: log)
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            try await drive.service.unmount(drive.connection)
            #expect(try FileManager.default.contentsOfDirectory(atPath: drive.paths.logs.path).count == 2)
            #expect(try #require(log.resourceValues(forKeys: [.fileSizeKey]).fileSize) < 1024 * 1024)
        }
    }

    @Test(arguments: [(false, false), (true, false), (false, true), (true, true)])
    func reconnectPreservesCachedFilesWhenControlIsUnavailable(staleSocket: Bool, reopened: Bool) async throws {
        try await withDrive { drive in
            let credentials = Credentials(accessKey: "test-key", secretKey: "test-secret")
            try Data("remote file".utf8).write(to: drive.bucket.appendingPathComponent("hello.txt"))
            try await drive.service.mount(drive.connection, credentials: credentials)
            #expect(try String(contentsOf: drive.mounted.appendingPathComponent("hello.txt"), encoding: .utf8) == "remote file")
            let diskCache = try #require(try await drive.control("vfs/stats")["diskCache"] as? [String: Any])
            let cached = URL(filePath: try #require(diskCache["path"] as? String)).appendingPathComponent("hello.txt")
            #expect(try String(contentsOf: cached, encoding: .utf8) == "remote file")
            let service = reopened ? drive.reopen() : drive.service
            let socket = drive.paths.socket(drive.connection)
            let hiddenSocket = socket.appendingPathExtension("hidden")
            try FileManager.default.moveItem(at: socket, to: hiddenSocket)
            defer {
                if !FileManager.default.fileExists(atPath: socket.path) {
                    try? FileManager.default.moveItem(at: hiddenSocket, to: socket)
                }
            }
            if staleSocket { FileManager.default.createFile(atPath: socket.path, contents: Data()) }
            let unhealthy = await service.status(drive.connection)
            #expect(unhealthy.isMounted)
            #expect(unhealthy.needsReconnect)
            try await service.reconnect(drive.connection, credentials: credentials)
            let recovered = await service.status(drive.connection)
            #expect(recovered.isMounted)
            #expect(!recovered.needsReconnect)
            #expect(try String(contentsOf: cached, encoding: .utf8) == "remote file")
            #expect(try String(contentsOf: drive.mounted.appendingPathComponent("hello.txt"), encoding: .utf8) == "remote file")
            try await service.unmount(drive.connection)
            #expect(await !service.status(drive.connection).isActive)
        }
    }

    @Test func reconnectRestoresTheDriveAfterTheServiceCrashes() async throws {
        try await withDrive { drive in
            let credentials = Credentials(accessKey: "test-key", secretKey: "test-secret")
            try Data("remote file".utf8).write(to: drive.bucket.appendingPathComponent("hello.txt"))
            try await drive.service.mount(drive.connection, credentials: credentials)
            let pid = try #require(try await drive.control("core/pid")["pid"] as? Int)
            _ = try await Command.run(URL(filePath: "/bin/kill"), ["-KILL", "\(pid)"])
            try await Task.sleep(for: .seconds(4))
            let unhealthy = await drive.service.status(drive.connection)
            #expect(unhealthy.isMounted)
            #expect(unhealthy.needsReconnect)
            try await drive.service.reconnect(drive.connection, credentials: credentials)
            #expect(try String(contentsOf: drive.mounted.appendingPathComponent("hello.txt"), encoding: .utf8) == "remote file")
            try await drive.service.unmount(drive.connection)
        }
    }

    @Test func connectingAppliesBandwidthAndTransferLimits() async throws {
        let connection = try JSONDecoder().decode(Connection.self, from: Data("""
        {"bandwidthLimit":10000000,"bucket":"my-bucket","endpoint":"https://s3.example.com","id":"\(UUID())","name":"My files","provider":"Other","region":"auto","transfers":8}
        """.utf8))
        try await withDrive(connection: connection) { drive in
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            let options = try await drive.control("options/get")
            let main = try #require(options["main"] as? [String: Any])
            #expect(main["BwLimit"] as? String == "9.537Mi")
            #expect(main["Transfers"] as? Int64 == 8)
            try await drive.service.unmount(drive.connection)
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

    @Test(arguments: ["", #"clients/a"b,c"#])
    func encryptedDrivesAcceptValidDirectoryNames(folder: String) async throws {
        try await withDrive(folder: folder, encrypted: true) { drive in
            let storage = drive.bucket.appendingPathComponent(folder)
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            let password = try await Command.run(
                drive.executable, ["obscure", "-", "--config", "/dev/null"], input: "correct horse")
            _ = try await Command.run(
                drive.executable, ["mkdir", ":crypt:undecryptable", "--config", "/dev/null"],
                environment: [
                    "RCLONE_CRYPT_REMOTE": storage.path,
                    "RCLONE_CRYPT_PASSWORD": String(decoding: password, as: UTF8.self)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                ])
            try await drive.service.test(
                drive.connection,
                credentials: Credentials(
                    accessKey: "test-key", secretKey: "test-secret",
                    encryptionPassword: "correct horse"))
        }
    }

    @Test(arguments: [(Int64(0), Int64(-1)), (Int64(5) << 30, Int64(5) << 30)])
    func connectingAppliesTheCacheLimits(minimumFreeSpace: Int64, expected: Int64) async throws {
        try await withDrive { drive in
            var connection = drive.connection
            connection.cacheLimit = 512 << 20
            connection.minimumFreeSpace = minimumFreeSpace
            try await drive.service.mount(
                connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            let options = try await drive.control("options/get")
            let vfs = try #require(options["vfs"] as? [String: Any])
            #expect(vfs["CacheMaxSize"] as? Int64 == 512 << 20)
            #expect(vfs["CacheMinFreeSpace"] as? Int64 == expected)
            #expect((vfs["CacheMaxAge"] as? NSNumber)?.doubleValue == Double(Int64.max))
            #expect(vfs["CacheMode"] as? String == "full")
            try await drive.service.unmount(connection)
        }
    }

    @Test func readOnlyDriveRejectsWrites() async throws {
        try await withDrive(readOnly: true) { drive in
            try Data("hello from S3".utf8).write(
                to: drive.bucket.appendingPathComponent("hello.txt"))
            try await drive.service.mount(
                drive.connection,
                credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
            #expect(
                try String(
                    contentsOf: drive.mounted.appendingPathComponent("hello.txt"), encoding: .utf8)
                    == "hello from S3")
            #expect(throws: (any Error).self) {
                try Data("nope".utf8).write(to: drive.mounted.appendingPathComponent("upload.txt"))
            }
            #expect(throws: (any Error).self) {
                try FileManager.default.removeItem(
                    at: drive.mounted.appendingPathComponent("hello.txt"))
            }
            try await drive.service.unmount(drive.connection)
            #expect(
                FileManager.default.fileExists(
                    atPath: drive.bucket.appendingPathComponent("hello.txt").path))
            #expect(
                !FileManager.default.fileExists(
                    atPath: drive.bucket.appendingPathComponent("upload.txt").path))
        }
    }
}

let helpers = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .appendingPathComponent("../../../../libexec").standardized

struct Drive {
    let executable: URL
    let bucket: URL
    let paths: AppPaths
    let service: MountService
    let connection: Connection

    var mounted: URL { paths.mount(connection) }

    func reopen() -> MountService {
        MountService(executable: executable, helperDirectory: helpers, paths: paths)
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
        for _ in 0..<200 {
            let queue = try? await control("vfs/queue")["queue"] as? [[String: Any]]
            for item in (queue ?? []).compactMap({ $0["id"] as? Int }) {
                _ = try? await control("vfs/queue-set-expiry", "id=\(item)", "expiry=-60", "relative=true")
            }
            if await service.status(connection).pendingUploads == 0 { return }
            try await Task.sleep(for: .milliseconds(100))
        }
    }
}

func withDrive(
    folder: String = "", encrypted: Bool = false, readOnly: Bool = false, connection: Connection? = nil,
    _ body: (Drive) async throws -> Void
) async throws {
    let executable = URL(
        fileURLWithPath: try #require(ProcessInfo.processInfo.environment["RCLONE_BINARY"]))
    let root = URL(fileURLWithPath: "/tmp/uf-\(UUID().uuidString.prefix(8))")
    let bucket = root.appendingPathComponent("source/my-bucket")
    try FileManager.default.createDirectory(at: bucket, withIntermediateDirectories: true)
    let server = try await S3Server(executable: executable, root: root)
    defer { server.stop() }
    let paths = AppPaths(
        config: root.appendingPathComponent("config.json"),
        support: root.appendingPathComponent("app"),
        mounts: root.appendingPathComponent("drives"),
        logs: root.appendingPathComponent("logs")
    )
    var connection = connection ?? fixture(folder: folder)
    connection.endpoint = "http://127.0.0.1:19753"
    connection.encrypted = encrypted
    connection.readOnly = readOnly
    let service = MountService(executable: executable, helperDirectory: helpers, paths: paths)
    let drive = Drive(
        executable: executable, bucket: bucket, paths: paths, service: service,
        connection: connection)
    do {
        try await body(drive)
    } catch {
        try? await Task.sleep(for: .seconds(6))
        if await drive.service.status(connection).isMounted {
            _ = try? await Command.run(URL(filePath: "/sbin/umount"), [drive.mounted.path], timeout: .seconds(10))
        }
        try? await drive.service.unmount(connection)
        throw error
    }
    try FileManager.default.removeItem(at: root)
}

private func verifyUploadProgress(_ drive: Drive, service: MountService) async throws {
    _ = try await drive.control("core/bwlimit", "rate=1M")
    try Data(repeating: 42, count: 8 * 1024 * 1024).write(
        to: drive.mounted.appendingPathComponent("large.bin"))
    var sawProgress = false
    for _ in 0..<80 {
        sawProgress = try await service.activity(drive.connection).contains {
            $0.path == "large.bin" && $0.state == .uploading && ($0.bytesTransferred ?? 0) > 0
                && $0.size == 8 * 1024 * 1024
        }
        if sawProgress { break }
        try await Task.sleep(for: .milliseconds(250))
    }
    #expect(sawProgress)
    for _ in 0..<80 {
        if try await service.activity(drive.connection).isEmpty { break }
        try await Task.sleep(for: .milliseconds(250))
    }
    #expect(try await service.activity(drive.connection).isEmpty)
    #expect(await service.status(drive.connection).isMounted)
}

private struct S3Server {
    let process = Process()
    let log: FileHandle

    init(executable: URL, root: URL) async throws {
        let logURL = root.appendingPathComponent("server.log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        log = try FileHandle(forWritingTo: logURL)
        process.executableURL = executable
        process.arguments = [
            "serve", "s3", root.appendingPathComponent("source").path, "--addr", "127.0.0.1:19753",
            "--auth-key", "test-key,test-secret", "--dir-cache-time", "0s", "--config", "/dev/null"
        ]
        process.standardOutput = log
        process.standardError = log
        try process.run()
        try await Task.sleep(for: .seconds(1))
        try #require(
            process.isRunning,
            "S3 fixture could not start: \((try? String(contentsOf: logURL, encoding: .utf8)) ?? "")"
        )
    }

    func stop() {
        if process.isRunning {
            kill(process.processIdentifier, SIGKILL)
            var info = siginfo_t()
            waitid(P_PID, id_t(process.processIdentifier), &info, WEXITED | WNOWAIT)
        }
        try? log.close()
    }
}

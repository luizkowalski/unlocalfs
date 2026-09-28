import Foundation
import Testing
import UnlocalFSCore

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["RCLONE_BINARY"] != nil, "Set RCLONE_BINARY to run"))
struct MountTests {
    @Test func s3DriveReadsUploadsSurvivesReopeningAndUnmountsSafely() async throws {
        let binary = try #require(ProcessInfo.processInfo.environment["RCLONE_BINARY"])
        let root = URL(fileURLWithPath: "/tmp/uf-\(UUID().uuidString.prefix(8))")
        let source = root.appendingPathComponent("source/my-bucket")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data("hello from S3".utf8).write(to: source.appendingPathComponent("hello.txt"))
        let executable = URL(fileURLWithPath: binary)
        let server = try await S3Server(executable: executable, root: root)
        defer { server.stop() }
        let paths = appPaths(root)
        let service = MountService(executable: executable, helperDirectory: helpers, paths: paths)
        var connection = fixture()
        connection.endpoint = "http://127.0.0.1:19753"
        let credentials = Credentials(accessKey: "test-key", secretKey: "test-secret")
        try await service.test(connection, credentials: credentials)
        await #expect(throws: AppError.self) {
            try await service.test(connection, credentials: Credentials(accessKey: "test-key", secretKey: "wrong"))
        }
        try await service.mount(connection, credentials: credentials)
        do {
            let mounted = paths.mount(connection)
            #expect(try String(contentsOf: mounted.appendingPathComponent("hello.txt"), encoding: .utf8) == "hello from S3")
            try Data("written through Finder's filesystem".utf8).write(to: mounted.appendingPathComponent("upload.txt"))
            #expect(try await service.status(connection).pendingUploads > 0)
            let activity = try await service.activity(connection)
            #expect(activity.contains { $0.path == "upload.txt" && $0.state == .queued })
            await #expect(throws: AppError.self) { try await service.unmount(connection) }
            let reopened = MountService(executable: executable, helperDirectory: helpers, paths: paths)
            #expect(try await reopened.status(connection).isMounted)
            for _ in 0..<40 {
                if try await reopened.status(connection).pendingUploads == 0 { break }
                try await Task.sleep(for: .milliseconds(500))
            }
            #expect(try String(contentsOf: source.appendingPathComponent("upload.txt"), encoding: .utf8) == "written through Finder's filesystem")
            #expect(try await reopened.activity(connection).isEmpty)
            try await verifyUploadProgress(service: reopened, connection: connection, paths: paths, executable: executable)
            try await reopened.unmount(connection)
            let stopped = try await reopened.status(connection)
            #expect(!stopped.isMounted && !stopped.isRunning)
            try FileManager.default.removeItem(at: root)
        } catch {
            try? await Task.sleep(for: .seconds(6))
            try? await service.unmount(connection)
            throw error
        }
    }

    @Test func folderDriveShowsOnlyThatFolder() async throws {
        let binary = try #require(ProcessInfo.processInfo.environment["RCLONE_BINARY"])
        let root = URL(fileURLWithPath: "/tmp/uf-\(UUID().uuidString.prefix(8))")
        let bucket = root.appendingPathComponent("source/my-bucket")
        let folder = bucket.appendingPathComponent("clients/acme")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("acme plan".utf8).write(to: folder.appendingPathComponent("plan.txt"))
        try Data("other client".utf8).write(to: bucket.appendingPathComponent("clients/other.txt"))
        let executable = URL(fileURLWithPath: binary)
        let server = try await S3Server(executable: executable, root: root)
        defer { server.stop() }
        let paths = appPaths(root)
        let service = MountService(executable: executable, helperDirectory: helpers, paths: paths)
        var connection = fixture()
        connection.endpoint = "http://127.0.0.1:19753"
        connection.folder = "clients/acme"
        try await service.mount(connection, credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
        do {
            let mounted = paths.mount(connection)
            #expect(try FileManager.default.contentsOfDirectory(atPath: mounted.path) == ["plan.txt"])
            #expect(try String(contentsOf: mounted.appendingPathComponent("plan.txt"), encoding: .utf8) == "acme plan")
            try await service.unmount(connection)
            try FileManager.default.removeItem(at: root)
        } catch {
            try? await service.unmount(connection)
            throw error
        }
    }

    @Test func encryptedDriveUploadsOnlyCiphertextAndRejectsTheWrongPassword() async throws {
        let binary = try #require(ProcessInfo.processInfo.environment["RCLONE_BINARY"])
        let root = URL(fileURLWithPath: "/tmp/uf-\(UUID().uuidString.prefix(8))")
        let bucket = root.appendingPathComponent("source/my-bucket")
        try FileManager.default.createDirectory(at: bucket, withIntermediateDirectories: true)
        let executable = URL(fileURLWithPath: binary)
        let server = try await S3Server(executable: executable, root: root)
        defer { server.stop() }
        let paths = appPaths(root)
        let service = MountService(executable: executable, helperDirectory: helpers, paths: paths)
        var connection = fixture()
        connection.endpoint = "http://127.0.0.1:19753"
        connection.encrypted = true
        let credentials = try await service.prepareCredentials(
            Credentials(accessKey: "test-key", secretKey: "test-secret", encryptionPassword: "correct horse")
        )
        try await service.mount(connection, credentials: credentials)
        do {
            let mounted = paths.mount(connection)
            try Data("top secret".utf8).write(to: mounted.appendingPathComponent("secret plan.txt"))
            for _ in 0..<40 {
                if try await service.status(connection).pendingUploads == 0 { break }
                try await Task.sleep(for: .milliseconds(500))
            }
            let stored = try FileManager.default.subpathsOfDirectory(atPath: bucket.path)
            let object = try #require(stored.first)
            #expect(stored.count == 1)
            #expect(!object.contains("secret"))
            #expect(try !String(decoding: Data(contentsOf: bucket.appendingPathComponent(object)), as: UTF8.self).contains("top secret"))
            try await service.unmount(connection)
            let reopened = MountService(executable: executable, helperDirectory: helpers, paths: paths)
            let savedCredentials = try JSONDecoder().decode(Credentials.self, from: JSONEncoder().encode(credentials))
            try await reopened.mount(connection, credentials: savedCredentials)
            #expect(try await reopened.status(connection).bytesCached == 10)
            try await reopened.unmount(connection)
            try FileManager.default.removeItem(at: paths.cache(connection))
            try await service.mount(connection, credentials: credentials)
            #expect(try String(contentsOf: mounted.appendingPathComponent("secret plan.txt"), encoding: .utf8) == "top secret")
            try await service.unmount(connection)
            var wrong = credentials
            wrong.encryptionPassword = "wrong"
            await #expect { try await service.test(connection, credentials: wrong) } throws: { $0.localizedDescription.contains("undecryptable") }
            await #expect { try await service.mount(connection, credentials: wrong) } throws: { $0.localizedDescription.contains("undecryptable") }
            #expect(try await !service.status(connection).isActive)
            try FileManager.default.removeItem(at: root)
        } catch {
            try? await Task.sleep(for: .seconds(6))
            try? await service.unmount(connection)
            throw error
        }
    }

    @Test(arguments: ["", #"clients/a"b,c"#])
    func encryptedDrivesAcceptValidDirectoryNames(folder: String) async throws {
        let executable = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["RCLONE_BINARY"]))
        let root = URL(fileURLWithPath: "/tmp/uf-\(UUID().uuidString.prefix(8))")
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = root.appendingPathComponent("source/my-bucket").appendingPathComponent(folder)
        try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
        let password = try await Command.run(executable, ["obscure", "-", "--config", "/dev/null"], input: "correct horse")
        _ = try await Command.run(executable, ["mkdir", ":crypt:undecryptable", "--config", "/dev/null"], environment: [
            "RCLONE_CRYPT_REMOTE": storage.path,
            "RCLONE_CRYPT_PASSWORD": String(decoding: password, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        ])
        let server = try await S3Server(executable: executable, root: root)
        defer { server.stop() }
        let service = MountService(executable: executable, helperDirectory: helpers, paths: appPaths(root))
        var connection = fixture(folder: folder)
        connection.endpoint = "http://127.0.0.1:19753"
        connection.encrypted = true
        try await service.test(connection, credentials: Credentials(accessKey: "test-key", secretKey: "test-secret", encryptionPassword: "correct horse"))
    }

    @Test func readOnlyDriveRejectsWrites() async throws {
        let binary = try #require(ProcessInfo.processInfo.environment["RCLONE_BINARY"])
        let root = URL(fileURLWithPath: "/tmp/uf-\(UUID().uuidString.prefix(8))")
        let source = root.appendingPathComponent("source/my-bucket")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data("hello from S3".utf8).write(to: source.appendingPathComponent("hello.txt"))
        let executable = URL(fileURLWithPath: binary)
        let server = try await S3Server(executable: executable, root: root)
        defer { server.stop() }
        let paths = appPaths(root)
        let service = MountService(executable: executable, helperDirectory: helpers, paths: paths)
        var connection = fixture()
        connection.endpoint = "http://127.0.0.1:19753"
        connection.readOnly = true
        try await service.mount(connection, credentials: Credentials(accessKey: "test-key", secretKey: "test-secret"))
        do {
            let mounted = paths.mount(connection)
            #expect(try String(contentsOf: mounted.appendingPathComponent("hello.txt"), encoding: .utf8) == "hello from S3")
            #expect(throws: (any Error).self) { try Data("nope".utf8).write(to: mounted.appendingPathComponent("upload.txt")) }
            #expect(throws: (any Error).self) { try FileManager.default.removeItem(at: mounted.appendingPathComponent("hello.txt")) }
            try await service.unmount(connection)
            #expect(FileManager.default.fileExists(atPath: source.appendingPathComponent("hello.txt").path))
            #expect(!FileManager.default.fileExists(atPath: source.appendingPathComponent("upload.txt").path))
            try FileManager.default.removeItem(at: root)
        } catch {
            try? await service.unmount(connection)
            throw error
        }
    }
}

private let helpers = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../../libexec").standardized

private func appPaths(_ root: URL) -> AppPaths {
    AppPaths(
        config: root.appendingPathComponent("config.json"),
        support: root.appendingPathComponent("app"),
        mounts: root.appendingPathComponent("drives"),
        logs: root.appendingPathComponent("logs")
    )
}

private func verifyUploadProgress(service: MountService, connection: Connection, paths: AppPaths, executable: URL) async throws {
    _ = try await Command.run(executable, [
        "rc", "--unix-socket", paths.socket(connection).path, "core/bwlimit", "rate=1M", "--config", "/dev/null"
    ])
    try Data(repeating: 42, count: 8 * 1024 * 1024).write(to: paths.mount(connection).appendingPathComponent("large.bin"))
    var sawProgress = false
    for _ in 0..<80 {
        sawProgress = try await service.activity(connection).contains {
            $0.path == "large.bin" && $0.state == .uploading && ($0.bytesTransferred ?? 0) > 0 && $0.size == 8 * 1024 * 1024
        }
        if sawProgress { break }
        try await Task.sleep(for: .milliseconds(250))
    }
    #expect(sawProgress)
    for _ in 0..<80 {
        if try await service.activity(connection).isEmpty { break }
        try await Task.sleep(for: .milliseconds(250))
    }
    #expect(try await service.activity(connection).isEmpty)
    #expect(try await service.status(connection).isMounted)
}

private struct S3Server {
    let process = Process()
    let log: FileHandle

    init(executable: URL, root: URL) async throws {
        let logURL = root.appendingPathComponent("server.log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        log = try FileHandle(forWritingTo: logURL)
        process.executableURL = executable
        process.arguments = ["serve", "s3", root.appendingPathComponent("source").path, "--addr", "127.0.0.1:19753", "--auth-key", "test-key,test-secret", "--config", "/dev/null"]
        process.standardOutput = log
        process.standardError = log
        try process.run()
        try await Task.sleep(for: .seconds(1))
        try #require(process.isRunning, "S3 fixture could not start: \((try? String(contentsOf: logURL, encoding: .utf8)) ?? "")")
    }

    func stop() {
        if process.isRunning { process.terminate() }
        try? log.close()
    }
}

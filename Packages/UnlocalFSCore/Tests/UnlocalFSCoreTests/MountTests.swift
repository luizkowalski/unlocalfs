import Foundation
import Testing
import UnlocalFSCore

@Suite(.enabled(if: ProcessInfo.processInfo.environment["RCLONE_BINARY"] != nil, "Set RCLONE_BINARY to run"))
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
        let paths = AppPaths(
            config: root.appendingPathComponent("config.json"),
            support: root.appendingPathComponent("app"),
            mounts: root.appendingPathComponent("drives"),
            logs: root.appendingPathComponent("logs")
        )
        let helpers = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../../libexec").standardized
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
            await #expect(throws: AppError.self) { try await service.unmount(connection) }
            let reopened = MountService(executable: executable, helperDirectory: helpers, paths: paths)
            #expect(try await reopened.status(connection).isMounted)
            for _ in 0..<40 {
                if try await reopened.status(connection).pendingUploads == 0 { break }
                try await Task.sleep(for: .milliseconds(500))
            }
            #expect(try String(contentsOf: source.appendingPathComponent("upload.txt"), encoding: .utf8) == "written through Finder's filesystem")
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

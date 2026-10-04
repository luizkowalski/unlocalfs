import Foundation
import Testing

struct S3Server {
    let process = Process()
    let log: FileHandle
    let endpoint: String

    init(executable: URL, root: URL) async throws {
        let logURL = root.appendingPathComponent("server.log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        log = try FileHandle(forWritingTo: logURL)
        let address = "127.0.0.1:\(try freePort())"
        endpoint = "http://\(address)"
        process.executableURL = executable
        process.arguments = [
            "serve", "s3", root.appendingPathComponent("source").path, "--addr", address,
            "--auth-key", "test-key,test-secret", "--dir-cache-time", "0s", "--config", "/dev/null"
        ]
        process.standardOutput = log
        process.standardError = log
        try process.run()
        let serving = { (try? String(contentsOf: logURL, encoding: .utf8))?.contains("Starting s3 server") ?? false }
        try await waitUntil { !process.isRunning || serving() }
        if !serving() { process.terminate() }
        try #require(
            process.isRunning && serving(),
            "S3 fixture could not start: \((try? String(contentsOf: logURL, encoding: .utf8)) ?? "")"
        )
    }

    func stop() {
        if process.isRunning { process.terminate() }
        try? log.close()
    }
}

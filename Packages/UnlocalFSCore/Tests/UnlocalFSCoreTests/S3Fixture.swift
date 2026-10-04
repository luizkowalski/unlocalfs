import Foundation
import Testing

struct S3Server {
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

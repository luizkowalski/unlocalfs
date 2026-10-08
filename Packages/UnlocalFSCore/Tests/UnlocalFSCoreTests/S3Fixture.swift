import Foundation

struct S3Server {
    let endpoint: String

    init(executable: URL, resources: FixtureResources) async throws {
        let process = try await resources.start(executable, arguments: [
            "serve", "s3", resources.root.appending(path: "source").path, "--addr", "127.0.0.1:0",
            "--auth-key", "test-key,test-secret", "--dir-cache-time", "0s", "--config", "/dev/null"
        ], log: "server.log")
        endpoint = try await requireOutput(of: process, in: resources, matching: #/Starting s3 server on \[(http://127\.0\.0\.1:\d+)/\]/#)
    }
}

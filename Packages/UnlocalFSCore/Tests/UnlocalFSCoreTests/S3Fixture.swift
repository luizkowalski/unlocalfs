import Foundation
import UnlocalFSInfrastructure

struct S3Server {
    let endpoint: String

    init(executable: URL, resources: FixtureResources) async throws {
        let root = resources.root
        let address = "127.0.0.1:\(try freePort())"
        endpoint = "http://\(address)"
        let process = try await resources.start(executable, arguments: [
            "serve", "s3", root.appending(path: "source").path, "--addr", address,
            "--auth-key", "test-key,test-secret", "--dir-cache-time", "0s", "--config", "/dev/null"
        ], log: "server.log")
        let environment = [
            "RCLONE_S3_PROVIDER": "Other", "RCLONE_S3_ENDPOINT": endpoint,
            "RCLONE_S3_ACCESS_KEY_ID": "test-key", "RCLONE_S3_SECRET_ACCESS_KEY": "test-secret"
        ]
        try await requireReady(process, log: root.appending(path: "server.log")) {
            _ = try await Command.run(executable, [
                "lsf", ":s3:", "--config", "/dev/null", "--retries", "1", "--low-level-retries", "1"
            ], environment: environment, timeout: .seconds(2))
        }
    }
}

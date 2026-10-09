import Foundation
import UnlocalFSDomain

let s3Credentials = Credentials(accessKey: "test-key", secretKey: "test-secret")

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

func withS3Drive(encrypted: Bool = false, _ body: (Drive, _ bucket: URL) async throws -> Void) async throws {
    let executable = try await rcloneExecutable.value
    try await withFixture { resources in
        let bucket = resources.root.appending(path: "source/my-bucket")
        try FileManager.default.createDirectory(at: bucket, withIntermediateDirectories: true)
        let server = try await S3Server(executable: executable, resources: resources)
        var connection = fixture(endpoint: server.endpoint)
        connection.encrypted = encrypted
        let drive = await makeDrive(executable: executable, resources: resources, connection: connection)
        try await body(drive, bucket)
    }
}

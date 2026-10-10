import Foundation
import UnlocalFSDomain

func withOfflineDrive(_ connection: Connection, _ body: (Drive) async throws -> Void) async throws {
    let executable = try await rcloneExecutable.value
    try await withFixture { resources in
        try await body(makeDrive(executable: executable, resources: resources, connection: connection))
    }
}

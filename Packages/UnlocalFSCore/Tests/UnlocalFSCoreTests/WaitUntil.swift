import Foundation
import UnlocalFSDomain

func waitUntil(
    timeout: Duration = .seconds(10), file: String = #fileID, line: Int = #line,
    _ condition: () async throws -> Bool
) async throws {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while !(try await condition()) {
        guard ContinuousClock.now < deadline else { throw AppError("Timed out after \(timeout) at \(file):\(line)") }
        try await Task.sleep(for: .milliseconds(50))
    }
}

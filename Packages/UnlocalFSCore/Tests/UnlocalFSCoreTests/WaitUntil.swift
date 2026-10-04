import Foundation

@discardableResult
func waitUntil(timeout: Duration = .seconds(10), _ condition: () async throws -> Bool) async throws -> Bool {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while !(try await condition()) {
        guard ContinuousClock.now < deadline else { return false }
        try await Task.sleep(for: .milliseconds(50))
    }
    return true
}

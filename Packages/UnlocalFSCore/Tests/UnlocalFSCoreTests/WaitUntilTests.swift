import Foundation
import Testing

@Suite struct WaitUntilTests {
    @Test func timeoutFailsAtTheWait() async {
        await #expect {
            try await waitUntil(timeout: .milliseconds(20)) { false }
        } throws: { error in
            error.localizedDescription.contains(#fileID + ":")
        }
    }

    @Test func satisfiedConditionCompletesImmediately() async throws {
        try await waitUntil(timeout: .zero) { true }
    }
}

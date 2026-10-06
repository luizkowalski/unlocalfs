import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure

@Suite(.timeLimit(.minutes(1))) struct CommandTests {
    @Test func commandsTimeOutInsteadOfHangingTheCaller() async {
        await #expect {
            _ = try await Command.run(URL(fileURLWithPath: "/bin/sleep"), ["3600"], timeout: .milliseconds(200))
        } throws: { error in
            error.localizedDescription == String(localized: .commandTimedOut)
        }
    }
}

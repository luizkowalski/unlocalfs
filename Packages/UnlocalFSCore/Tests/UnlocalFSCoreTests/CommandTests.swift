import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite struct CommandTests {
    @Test func commandsTimeOutInsteadOfHangingTheCaller() async {
        let start = Date()
        await #expect(throws: (any Error).self) { _ = try await Command.run(URL(fileURLWithPath: "/bin/sleep"), ["20"], timeout: .milliseconds(200)) }
        #expect(Date().timeIntervalSince(start) < 5)
    }
}

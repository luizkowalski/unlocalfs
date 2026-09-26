import Foundation
import Testing
import UnlocalFSCore

@Suite struct CommandTests {
    @Test func commandsReturnOutputWithoutInterpretingShellCharacters() async throws {
        let output = try await Command.run(URL(fileURLWithPath: "/usr/bin/printf"), ["%s", "a b;$(echo secret)"])
        #expect(String(decoding: output, as: UTF8.self) == "a b;$(echo secret)")
    }

    @Test func failedCommandsSurfaceTheirErrors() async {
        await #expect {
            _ = try await Command.run(URL(fileURLWithPath: "/bin/ls"), ["/unlocalfs-no-such-file"])
        } throws: { error in
            error.localizedDescription.contains("No such file")
        }
    }

    @Test func commandsTimeOutInsteadOfHangingTheCaller() async {
        let start = Date()
        await #expect(throws: (any Error).self) {
            _ = try await Command.run(URL(fileURLWithPath: "/bin/sleep"), ["20"], timeout: .milliseconds(200))
        }
        #expect(Date().timeIntervalSince(start) < 5)
    }
}

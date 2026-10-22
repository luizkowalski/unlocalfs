import Foundation
import Testing
@testable import UnlocalFSDomain
import UnlocalFSTestSupport
import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation

@MainActor @Suite final class AppPollingTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func everyDriveStatusIsCheckedAtTheSameTime() async throws {
        let overlap = Overlap()
        for name in ["First", "Second"] {
            try fixture.serve(Connection.s3(name: name)) { _ in
                overlap.hold()
                defer { overlap.release() }
                try await Task.sleep(for: .milliseconds(200))
                return #"{"results":[{"diskCache":{"uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0}},{"queue":[]},{\#(rcloneCounters)}]}"#
            }
        }
        let app = fixture.app()

        await app.refresh()

        #expect(overlap.peak == 2)
    }

    @Test func loginItemStateIsNotReadOnEveryPoll() async throws {
        let desktop = TestDesktopServices(paths: fixture.paths)
        let app = fixture.app(desktop: desktop)
        desktop.opensAtLogin = true

        await app.refresh()

        #expect(!app.opensAtLogin)
        app.syncOpensAtLogin()
        #expect(app.opensAtLogin)
    }
}

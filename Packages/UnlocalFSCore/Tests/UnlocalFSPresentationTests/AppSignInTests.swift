import Foundation
import Testing
@testable import UnlocalFSDomain
import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor final class AppSignInTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test(arguments: [
        ("couldn't fetch token: invalid_grant: maybe token expired?", true),
        ("dial tcp: lookup storage.googleapis.com: no such host", false),
    ])
    func onlyARevokedGrantAtConnectAsksToSignInAgain(failure: String, needsSignIn: Bool) async throws {
        let connection = Connection.gcs { $0.gcs.authentication = .googleAccount }
        try fixture.repository.save(connection, credentials: Credentials.google())
        try failure.write(to: fixture.root.appending(path: "test-error"), atomically: true, encoding: .utf8)
        let app = fixture.app()
        await app.refresh()

        await app.toggle(connection)

        #expect(app.needsSignIn(connection) == needsSignIn)
        #expect(app.problem(connection) != nil)
        #expect(fixture.rcloneCalls.filter { $0 == "authorize" }.isEmpty)
    }

    @Test func signingInAgainAfterARevokedGrantSavesTheNewToken() async throws {
        let connection = Connection.gcs { $0.gcs.authentication = .googleAccount }
        try fixture.repository.save(connection, credentials: Credentials.google())
        try "invalid_grant".write(to: fixture.root.appending(path: "test-error"), atomically: true, encoding: .utf8)
        let app = fixture.app()
        await app.refresh()
        await app.toggle(connection)
        #expect(app.needsSignIn(connection))
        try FileManager.default.removeItem(at: fixture.root.appending(path: "test-error"))
        let newToken = #"{"access_token":"ya29.new","refresh_token":"1//new-refresh"}"#
        try fixture.signInReturns(newToken)

        await app.signInAgain(connection)

        #expect(!app.needsSignIn(connection))
        #expect(app.problem(connection) == nil)
        #expect(!app.busy.contains(connection.id))
        #expect(try fixture.repository.credentials(for: connection.id).googleToken == newToken)
        #expect(app.statusText(connection) == String(localized: .disconnected))
    }

    @Test func cancellingTheBrowserStepOfSignInAgainChangesNothing() async throws {
        let connection = Connection.gcs { $0.gcs.authentication = .googleAccount }
        try fixture.repository.save(connection, credentials: Credentials.google())
        let app = fixture.app()
        await app.refresh()

        let signIn = Task { await app.signInAgain(connection) }
        let pid = try await fixture.signInHangs()
        #expect(app.isSigningIn(connection))
        #expect(!app.canConnect(connection))
        app.cancelSignIn(connection)
        await signIn.value

        #expect(kill(pid, 0) == -1)
        #expect(!app.isSigningIn(connection))
        #expect(!app.busy.contains(connection.id))
        #expect(app.problem(connection) == nil)
        #expect(try fixture.repository.credentials(for: connection.id) == Credentials.google())
        #expect(fixture.rcloneCalls == ["authorize"])
    }
}

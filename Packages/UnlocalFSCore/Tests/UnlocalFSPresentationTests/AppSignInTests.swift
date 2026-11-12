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
        (revokedGrantError, true),
        ("dial tcp: lookup storage.googleapis.com: no such host", false),
    ])
    func onlyARevokedGrantAtConnectAsksToSignInAgain(failure: String, needsSignIn: Bool) async throws {
        let connection = Connection.gcs(authentication: .googleAccount)
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
        let connection = Connection.gcs(authentication: .googleAccount)
        try fixture.repository.save(connection, credentials: Credentials.google())
        try revokedGrantError.write(to: fixture.root.appending(path: "test-error"), atomically: true, encoding: .utf8)
        let app = fixture.app()
        await app.refresh()
        await app.toggle(connection)
        #expect(app.needsSignIn(connection))
        try FileManager.default.removeItem(at: fixture.root.appending(path: "test-error"))
        try fixture.signInReturns(newTokenJSON)

        await app.signInAgain(connection)

        #expect(!app.needsSignIn(connection))
        #expect(app.problem(connection) == nil)
        #expect(!app.busy.contains(connection.id))
        #expect(try fixture.repository.credentials(for: connection.id).googleToken == newTokenJSON)
        #expect(app.statusText(connection) == String(localized: .disconnected))
        #expect(fixture.rcloneCalls == ["lsf", "authorize", "lsf"])
    }

    @Test func cancellingTheBrowserStepOfSignInAgainChangesNothing() async throws {
        let connection = Connection.gcs(authentication: .googleAccount)
        try fixture.repository.save(connection, credentials: Credentials.google())
        try revokedGrantError.write(to: fixture.root.appending(path: "test-error"), atomically: true, encoding: .utf8)
        let app = fixture.app()
        await app.refresh()
        await app.toggle(connection)
        let problem = app.problem(connection)

        try fixture.signInWillHang()
        let signIn = Task { await app.signInAgain(connection) }
        let pid = try await fixture.signInHangs()
        #expect(app.isSigningIn(connection))
        #expect(!app.canConnect(connection))
        app.cancelSignIn(connection)
        try await fixture.waitForSignInToStop(pid)
        await signIn.value

        #expect(!app.isSigningIn(connection))
        #expect(!app.busy.contains(connection.id))
        #expect(app.needsSignIn(connection))
        #expect(app.problem(connection) == problem)
        #expect(try fixture.repository.credentials(for: connection.id) == Credentials.google())
        #expect(fixture.rcloneCalls == ["lsf", "authorize"])
    }

    @Test func failedSignInAgainKeepsTheSavedAccountAndShowsWhy() async throws {
        let connection = Connection.gcs(authentication: .googleAccount)
        try fixture.repository.save(connection, credentials: Credentials.google())
        try "googleapi: Error 403: me@example.com does not have storage.objects.list access".write(
            to: fixture.root.appending(path: "test-error"), atomically: true, encoding: .utf8,
        )
        try fixture.signInReturns(newTokenJSON)
        let app = fixture.app()
        await app.refresh()

        await app.signInAgain(connection)

        #expect(app.problem(connection)?.contains("Error 403") == true)
        #expect(!app.busy.contains(connection.id))
        #expect(try fixture.repository.credentials(for: connection.id) == Credentials.google())
    }

    @Test(arguments: [
        (Connection.gcs(authentication: .googleAccount), revokedGrantError, true),
        (Connection.gcs(authentication: .googleAccount), "googleapi: Error 403: denied", false),
        (Connection.gcs(), revokedGrantError, false),
        (Connection.s3(), revokedGrantError, false),
    ])
    func onlyAGoogleDriveWithARevokedGrantAsksToSignInAgain(connection: Connection, lastError: String, needsSignIn: Bool) async throws {
        try fixture.serve(connection, failed: 1, lastError: lastError)
        let app = fixture.app()
        await app.refresh()

        #expect(app.needsSignIn(connection) == needsSignIn)
        #expect(app.statusText(connection) == (needsSignIn ? String(localized: .needsGoogleSignIn) : String(localized: .uploadNeedsAttention)))
        #expect(app.uploadFailure(connection)?.uploadError == (needsSignIn ? GoogleSignInRequired().localizedDescription : lastError))
    }

    @Test func uploadRetryingAfterANewSignInNoLongerAsksToSignIn() async throws {
        let connection = Connection.gcs(authentication: .googleAccount)
        try fixture.serve(connection, lastError: revokedGrantError)
        try fixture.queue(#"{"name":"a.txt","id":1,"size":1,"expiry":0,"tries":2,"delay":5,"uploading":true}"#)
        let app = fixture.app()
        await app.refresh()

        #expect(!app.needsSignIn(connection))
        #expect(app.statusText(connection) == String(localized: .uploadNeedsAttention))
    }

    @Test func quittingStopsAGoogleSignInThatWaitsInTheEditor() async throws {
        let app = fixture.app()
        let editor = fixture.editor(draft: .init(connection: Connection.gcs(authentication: .googleAccount)), app: app)
        editor.loadCredentials()
        try fixture.signInWillHang()
        let signIn = Task { await editor.signInWithGoogle() }
        let pid = try await fixture.signInHangs()

        await app.stopSignInsForQuit()

        #expect(kill(pid, 0) == -1)
        await signIn.value
        #expect(editor.credentials.googleToken.isEmpty)
    }
}

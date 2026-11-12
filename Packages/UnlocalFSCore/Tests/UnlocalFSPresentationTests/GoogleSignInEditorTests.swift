import Foundation
import Testing
@testable import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor final class GoogleSignInEditorTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func googleSignInHoldsTheNewTokenInTheDraftAndClearsTheEarlierTest() async throws {
        let editor = fixture.editor(draft: .init(connection: Connection.gcs(authentication: .googleAccount)))
        editor.loadCredentials()
        editor.credentials = Credentials.google()
        await editor.test()
        #expect(editor.tested)
        try fixture.signInReturns(newTokenJSON)

        await editor.signInWithGoogle()

        #expect(editor.credentials.googleToken == newTokenJSON)
        #expect(editor.credentials.isSignedInToGoogle)
        #expect(!editor.tested)
        #expect(!editor.signingIn)
        #expect(editor.error == nil)
        #expect(editor.fieldErrors.isEmpty)
        #expect(fixture.signInEnvironment.contains("RCLONE_GCS_CLIENT_ID=\(GoogleClient.test.id)"))
        #expect(fixture.signInEnvironment.contains("RCLONE_GCS_CLIENT_SECRET=\(GoogleClient.test.secret)"))
    }

    @Test func cancelledGoogleSignInStopsRcloneAndKeepsTheSavedAccount() async throws {
        let connection = Connection.gcs(authentication: .googleAccount)
        try fixture.repository.save(connection, credentials: Credentials.google())
        let editor = fixture.editor(draft: .init(connection: connection))
        editor.loadCredentials()

        try fixture.signInWillHang()
        let signIn = Task { await editor.signInWithGoogle() }
        let pid = try await fixture.signInHangs()
        #expect(editor.signingIn)
        #expect(editor.isLocked)
        await editor.signInWithGoogle()
        #expect(fixture.rcloneCalls.filter { $0 == "authorize" }.count == 1)
        editor.cancelSignIn()
        try await fixture.waitForSignInToStop(pid)
        await signIn.value

        #expect(!editor.signingIn)
        #expect(editor.error == nil)
        #expect(editor.credentials == Credentials.google())
        #expect(await editor.save())
        #expect(try fixture.repository.credentials(for: connection.id) == Credentials.google())
    }

    @Test func switchingTheGCSSignInMethodClearsTheTest() async {
        let editor = fixture.editor(draft: .init(connection: Connection.gcs(authentication: .googleAccount)))
        editor.loadCredentials()
        editor.credentials = Credentials.google()
        await editor.test()
        #expect(editor.tested)

        editor.connection.gcs.authentication = .serviceAccount

        #expect(!editor.tested)
        #expect(editor.credentials == Credentials.google())
        #expect(editor.firstInvalidField == .serviceAccountKey)
    }

    @Test func signInThatReturnsNoRefreshTokenKeepsTheEarlierToken() async throws {
        let editor = fixture.editor(draft: .init(connection: Connection.gcs(authentication: .googleAccount)))
        editor.loadCredentials()
        editor.credentials = Credentials.google()
        try fixture.signInReturns(#"{"access_token":"ya29.only-access","token_type":"Bearer"}"#)

        await editor.signInWithGoogle()

        #expect(editor.error == String(localized: .googleSignInFailed))
        #expect(editor.credentials == Credentials.google())
    }

    @Test func failedGoogleSignInShowsRclonesReasonAndKeepsTheEarlierToken() async throws {
        let editor = fixture.editor(draft: .init(connection: Connection.gcs(authentication: .googleAccount)))
        editor.loadCredentials()
        editor.credentials = Credentials.google()
        try fixture.signInFails("""
        Error: config failed to refresh token: failed to start auth webserver: listen tcp 127.0.0.1:53682: bind: address already in use
        Usage:
          rclone authorize <backendname> [base64_json_blob | client_id client_secret] [flags]

        2026/11/12 00:05:39 NOTICE: Fatal error: config failed to refresh token: failed to start auth webserver: listen tcp 127.0.0.1:53682: bind: address already in use
        """)

        await editor.signInWithGoogle()

        #expect(editor.error == "config failed to refresh token: failed to start auth webserver: listen tcp 127.0.0.1:53682: bind: address already in use")
        #expect(editor.credentials == Credentials.google())
    }

    @Test func buildWithoutAGoogleClientCannotSignIn() async throws {
        let fixture = try ViewModelFixture(googleClient: GoogleClient(id: "", secret: ""))
        defer { fixture.remove() }
        let editor = fixture.editor(draft: .init(connection: Connection.gcs(authentication: .googleAccount)))
        editor.loadCredentials()

        await editor.signInWithGoogle()

        #expect(editor.error == String(localized: .googleSignInUnavailable))
        #expect(fixture.rcloneCalls.isEmpty)
    }
}

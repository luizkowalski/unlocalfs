import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

@MainActor @Suite struct ConnectionEditorViewModelTests {
    @Test func invalidConnectionShowsFieldErrorsWithoutSaving() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = Connection()
        let editor = fixture.editor(draft: .init(connection: connection))

        #expect(editor.fieldErrors.isEmpty)
        #expect(await editor.save() == false)

        #expect(editor.firstInvalidField == .name)
        #expect(editor.fieldErrors[.endpoint] != nil)
        #expect(editor.fieldErrors[.accessKey] != nil)
        #expect(!editor.saving)
        #expect(!FileManager.default.fileExists(atPath: fixture.paths.config.path))
    }

    @Test func duplicateLoadsTheOriginalCredentials() throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        var connection = connectionFixture()
        connection.encrypted = true
        let credentials = Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "password")
        try fixture.repository.save(connection, credentials: credentials)
        let app = fixture.app()

        app.duplicate(connection)
        let editor = fixture.editor(draft: try #require(app.editor), app: app)
        editor.loadCredentials()

        #expect(editor.title == "Duplicate connection")
        #expect(editor.connection.id != connection.id)
        #expect(editor.connection.name == "My files copy")
        #expect(editor.credentials == credentials)
        #expect(editor.confirmation == "password")
        #expect(!editor.isLocked)
    }

    @Test func newEncryptedConnectionRequiresMatchingPasswords() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        var connection = connectionFixture()
        connection.encrypted = true
        let editor = fixture.editor(draft: .init(connection: connection))
        editor.credentials = Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "password")
        editor.confirmation = "different"

        await editor.test()

        #expect(editor.firstInvalidField == .confirmation)
        #expect(editor.fieldErrors[.confirmation] == "The passwords do not match.")
        #expect(!editor.tested)
    }

    @Test func duplicateDriveNameIsCheckedAgainstSavedConnections() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        try ConnectionStore(url: fixture.paths.config).save(connectionFixture())
        var connection = connectionFixture()
        connection.name = "my files"
        let editor = fixture.editor(draft: .init(connection: connection))
        editor.credentials = Credentials(accessKey: "key", secretKey: "secret")

        #expect(await editor.save() == false)

        #expect(editor.firstInvalidField == .name)
        #expect(try ConnectionStore(url: fixture.paths.config).all().count == 1)
    }

    @Test func changingTheEndpointClearsTheSuccessfulTest() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        let editor = fixture.editor(draft: .init(connection: connection))
        editor.credentials = Credentials(accessKey: "key", secretKey: "secret")
        await editor.test()
        #expect(editor.tested)

        editor.connection.endpoint = "https://other.example.com"

        #expect(!editor.tested)
    }

    @Test func changingCredentialsClearsTheSuccessfulTest() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = connectionFixture()
        let editor = fixture.editor(draft: .init(connection: connection))
        editor.credentials = Credentials(accessKey: "key", secretKey: "secret")
        await editor.test()
        #expect(editor.tested)

        editor.credentials.secretKey = "new-secret"

        #expect(!editor.tested)
    }

    @Test func failedConnectionTestShowsAnErrorWithoutCredentials() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        try "Cannot connect with test-secret".write(to: fixture.root.appending(path: "test-error"), atomically: true, encoding: .utf8)
        let connection = connectionFixture()
        let editor = fixture.editor(draft: .init(connection: connection))
        editor.credentials = Credentials(accessKey: "key", secretKey: "test-secret")

        await editor.test()

        let error = try #require(editor.error)
        #expect(error.contains("Cannot connect"))
        #expect(!error.contains("test-secret"))
        #expect(!editor.tested)
        #expect(!editor.testing)
    }

    @Test func failedSaveKeepsTheDraftAndShowsAnError() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let app = fixture.app()
        let connection = connectionFixture()
        let editor = fixture.editor(draft: .init(connection: connection), app: app)
        editor.credentials = Credentials(accessKey: "key", secretKey: "secret")
        try FileManager.default.createDirectory(at: fixture.paths.config, withIntermediateDirectories: true)

        #expect(await editor.save() == false)

        #expect(editor.error != nil)
        #expect(!editor.saving)
        #expect(editor.connection == connection)
        #expect(app.connections.isEmpty)
    }
}

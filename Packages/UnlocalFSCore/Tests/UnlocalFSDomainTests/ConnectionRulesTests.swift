import Foundation
import Testing
import UnlocalFSDomain

@Suite struct ConnectionRulesTests {
    @Test func duplicateUsesANewIdentityAndKeepsTheCredentialsSource() {
        var connection = Connection()
        connection.name = "Photos"
        let draft = ConnectionDraft(duplicating: connection)
        #expect(draft.id != connection.id)
        #expect(draft.connection.name == "Photos copy")
        #expect(draft.credentialsSource == connection.id)
        #expect(draft.isDuplicate)
    }

    @Test func driveNamesAreUniqueRegardlessOfCase() {
        var duplicate = fixture()
        duplicate.name = "my files"
        #expect(duplicate.validate(against: [fixture()]).issues.map(\.field) == [.name])
    }

    @Test func newEncryptedDriveRequiresMatchingPasswords() {
        var connection = Connection()
        connection.name = "Photos"
        connection.endpoint = "https://s3.example.com"
        connection.bucket = "photos"
        connection.encrypted = true
        let credentials = Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "password")
        let errors = connection.validate(credentials: credentials, confirmation: "different", against: [])
        #expect(errors.issues.map(\.field) == [.confirmation])
        #expect(connection.validate(credentials: credentials, confirmation: "password", against: []).isValid)
    }

    @Test func existingEncryptedDriveDoesNotRequirePasswordConfirmation() {
        var connection = Connection()
        connection.name = "Photos"
        connection.endpoint = "https://s3.example.com"
        connection.bucket = "photos"
        connection.encrypted = true
        let credentials = Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "password")
        #expect(connection.validate(credentials: credentials, confirmation: "", against: [connection]).isValid)
    }

    @Test func unchangedIdentityKeepsItsName() {
        let connection = fixture()
        #expect(connection.validate(against: [connection]).isValid)
    }

    @Test func saveIssuesKeepConnectionCredentialsAndConfirmationOrder() {
        var connection = fixture(name: "my files", folder: "bad//folder")
        connection.encrypted = true
        let errors = connection.validate(credentials: Credentials(), confirmation: "different", against: [fixture()])
        #expect(errors.issues == [
            .init(field: .folder, message: "Enter a folder path like clients/acme, or leave it empty to use the whole bucket."),
            .init(field: .name, message: "A drive with that name already exists."),
            .init(field: .accessKey, message: "Access key cannot be empty"),
            .init(field: .secretKey, message: "Secret key cannot be empty"),
            .init(field: .encryptionPassword, message: "Encryption password cannot be empty"),
            .init(field: .confirmation, message: "The passwords do not match.")
        ])
        #expect { try errors.requireValid() } throws: { error in
            (error as? AppError)?.errorDescription == """
            Enter a folder path like clients/acme, or leave it empty to use the whole bucket.
            A drive with that name already exists.
            Access key cannot be empty
            Secret key cannot be empty
            Encryption password cannot be empty
            The passwords do not match.
            """
        }
    }

    @Test func duplicatedEncryptedDriveRequiresConfirmation() {
        var connection = fixture()
        connection.encrypted = true
        let draft = ConnectionDraft(duplicating: connection)
        let credentials = Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "password")
        #expect(draft.connection.validate(credentials: credentials, confirmation: "", against: [connection]).issues.map(\.field) == [.confirmation])
    }

    @Test func unencryptedDriveIgnoresConfirmation() {
        let credentials = Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "password")
        #expect(fixture().validate(credentials: credentials, confirmation: "different", against: []).isValid)
    }

    @Test func automaticConnectionRequiresAnEnabledInactiveDrive() {
        var connection = Connection()
        let disconnected = MountStatus()
        #expect(!connection.shouldConnectAutomatically(status: disconnected))
        connection.connectsAutomatically = true
        #expect(connection.shouldConnectAutomatically(status: disconnected))
        var active = MountStatus()
        active.isRunning = true
        #expect(!connection.shouldConnectAutomatically(status: active))
        active.isRunning = false
        active.controlError = "Unavailable"
        #expect(!connection.shouldConnectAutomatically(status: active))
    }

    @Test func pendingUploadsPreventDisconnect() {
        var status = MountStatus()
        status.pendingUploads = 1
        #expect(throws: UploadsPendingError.self) { try status.requireSafeDisconnect() }
    }

    @Test func failedUploadsPreventDisconnect() {
        var status = MountStatus()
        status.failedUploads = 1
        #expect(throws: AppError.self) { try status.requireSafeDisconnect() }
    }
}

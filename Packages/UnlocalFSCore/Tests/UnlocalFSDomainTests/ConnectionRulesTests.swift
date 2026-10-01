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
        #expect(duplicate.validate(against: [fixture()]).map(\.connectionField) == [.name])
    }

    @Test func newEncryptedDriveRequiresMatchingPasswords() {
        var connection = Connection()
        connection.name = "Photos"
        connection.endpoint = "https://s3.example.com"
        connection.bucket = "photos"
        connection.encrypted = true
        let credentials = Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "password")
        let errors = connection.validate(credentials: credentials, confirmation: "different", against: [])
        #expect(errors.map(\.connectionField) == [.confirmation])
        #expect(connection.validate(credentials: credentials, confirmation: "password", against: []).isEmpty)
    }

    @Test func existingEncryptedDriveDoesNotRequirePasswordConfirmation() {
        var connection = Connection()
        connection.name = "Photos"
        connection.endpoint = "https://s3.example.com"
        connection.bucket = "photos"
        connection.encrypted = true
        let credentials = Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "password")
        #expect(connection.validate(credentials: credentials, confirmation: "", against: [connection]).isEmpty)
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

import Foundation
import Testing
@testable import UnlocalFSDomain

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

    @Test func saveIssuesKeepConnectionCredentialsAndConfirmationOrder() {
        var connection = fixture(name: "my files", folder: "bad//folder")
        connection.encrypted = true
        let errors = connection.validate(credentials: Credentials(), confirmation: "different", against: [fixture()])
        #expect(errors.issues == [
            .init(field: .folder, message: String(localized: .folderPathInvalid)),
            .init(field: .name, message: String(localized: .nameAlreadyExists)),
            .init(field: .accessKey, message: String(localized: .accessKeyEmpty)),
            .init(field: .secretKey, message: String(localized: .secretKeyEmpty)),
            .init(field: .encryptionPassword, message: String(localized: .encryptionPasswordEmpty)),
            .init(field: .confirmation, message: String(localized: .passwordsDoNotMatch))
        ])
        #expect { try errors.requireValid() } throws: { error in
            (error as? AppError)?.errorDescription == [
                String(localized: .folderPathInvalid), String(localized: .nameAlreadyExists), String(localized: .accessKeyEmpty),
                String(localized: .secretKeyEmpty), String(localized: .encryptionPasswordEmpty), String(localized: .passwordsDoNotMatch)
            ].joined(separator: "\n")
        }
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

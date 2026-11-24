import Foundation
import Testing
@testable import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSTestSupport

struct WorkflowTests {
    @Test func saveRejectsANameAddedAfterTheEditorOpened() async throws {
        try await withWorkflowFixture { repository, drives, connection in
            let original = Credentials.s3()
            try repository.save(connection, credentials: original)
            let config = try Data(contentsOf: drives.paths.config)
            var draft = connection
            draft.id = UUID()
            draft.encrypted = true
            await #expect(throws: AppError.self) {
                _ = try await SaveConnectionUseCase(repository: repository, drives: drives.service)
                    .execute(draft, credentials: Credentials(accessKey: "new-key", secretKey: "new-secret", encryptionPassword: "password"), confirmation: "password")
            }
            #expect(try Data(contentsOf: drives.paths.config) == config)
            #expect(try repository.credentials(for: connection.id) == original)
            #expect(try repository.credentials(for: draft.id) == Credentials())
            #expect(drives.rcloneCalls.isEmpty)
        }
    }

    @Test(arguments: LockedChange.allCases)
    func aSavedDriveKeepsItsProtocolFolderAndEncryption(change: LockedChange) async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let drive = change.drive
            try repository.save(drive.saved, credentials: drive.savedCredentials)
            await #expect(throws: AppError.self) {
                _ = try await SaveConnectionUseCase(repository: repository, drives: drives.service)
                    .execute(drive.edited, credentials: drive.editedCredentials, confirmation: drive.editedCredentials.encryptionPassword)
            }
            #expect(try repository.all() == [drive.saved])
            #expect(try repository.credentials(for: drive.saved.id) == drive.savedCredentials)
        }
    }

    @Test func savedSFTPDriveKeepsEditingHostPortAndUsername() async throws {
        try await withWorkflowFixture { repository, drives, _ in
            var connection = Connection.sftp()
            try repository.save(connection, credentials: Credentials(password: "secret"))
            connection.sftp.host = "other.example.com"
            connection.sftp.port = 2222
            connection.sftp.username = "other"
            let saved = try await SaveConnectionUseCase(repository: repository, drives: drives.service)
                .execute(connection, credentials: Credentials(password: "secret"))
            #expect(saved == [connection])
        }
    }

    @Test func savedSFTPDriveKeepsEditingAuthentication() async throws {
        try await withWorkflowFixture { repository, drives, _ in
            var connection = Connection.sftp { $0.encrypted = true }
            try repository.save(connection, credentials: Credentials(encryptionPassword: "crypt", password: "secret"))
            connection.sftp.authentication = .privateKey
            connection.sftp.keyFile = "/Users/me/.ssh/id_ed25519"
            connection.readOnly = true
            let saved = try await SaveConnectionUseCase(repository: repository, drives: drives.service)
                .execute(connection, credentials: Credentials(encryptionPassword: "crypt", password: "secret", keyPassphrase: "phrase"))
            #expect(saved == [connection])
            #expect(try repository.credentials(for: connection.id) == Credentials(encryptionPassword: "crypt", keyPassphrase: "phrase"))
        }
    }

    @Test(arguments: [(GCSAuthentication.googleAccount, Credentials.google()), (.serviceAccount, Credentials(serviceAccountKey: serviceAccountJSON))])
    func savingAGCSDriveKeepsOnlyTheSelectedAuthentication(authentication: GCSAuthentication, expected: Credentials) async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let connection = Connection.gcs { $0.gcs.authentication = authentication }
            _ = try await SaveConnectionUseCase(repository: repository, drives: drives.service).execute(
                connection, credentials: Credentials(accessKey: "key", password: "ssh", serviceAccountKey: serviceAccountJSON, googleToken: googleTokenJSON),
            )
            let saved = try repository.credentials(for: connection.id)
            #expect(saved == expected)
        }
    }

    @Test func savingAGoogleDriveKeepsOnlyItsSignInAndEncryptionPassword() async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let connection = Connection.googleDrive { $0.encrypted = true }
            _ = try await SaveConnectionUseCase(repository: repository, drives: drives.service).execute(
                connection, credentials: Credentials(
                    accessKey: "key", secretKey: "secret", sessionToken: "token", encryptionPassword: "crypt", password: "ssh",
                    keyPassphrase: "phrase", serviceAccountKey: serviceAccountJSON, googleToken: googleTokenJSON, googleAccountID: "account-1",
                ),
                confirmation: "crypt",
            )
            let saved = try repository.credentials(for: connection.id)
            #expect(saved == Credentials(encryptionPassword: "crypt", googleToken: googleTokenJSON, googleAccountID: "account-1"))
        }
    }

    @Test(arguments: [(SFTPAuthentication.password, "ssh", ""), (.privateKey, "", "phrase"), (.agent, "", "")])
    func savingKeepsOnlyTheSecretsOfTheSelectedAuthentication(authentication: SFTPAuthentication, password: String, passphrase: String) async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let connection = Connection.sftp {
                $0.encrypted = true
                $0.sftp.authentication = authentication
                $0.sftp.keyFile = "/Users/me/.ssh/id_ed25519"
            }
            try repository.save(connection, credentials: Credentials(encryptionPassword: "crypt"))
            _ = try await SaveConnectionUseCase(repository: repository, drives: drives.service).execute(
                connection, credentials: Credentials(
                    accessKey: "key", secretKey: "secret", sessionToken: "token", encryptionPassword: "crypt",
                    password: "ssh", keyPassphrase: "phrase",
                ),
            )
            let saved = try repository.credentials(for: connection.id)
            #expect(saved == Credentials(encryptionPassword: "crypt", password: password, keyPassphrase: passphrase))
        }
    }

    @Test func duplicatingASFTPDriveAllowsANewFolderUnderANewIdentity() async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let original = Connection.sftp()
            try repository.save(original, credentials: Credentials(password: "secret"))
            var draft = ConnectionDraft(duplicating: original)
            draft.connection.sftp.remotePath = "/elsewhere"

            let saved = try await SaveConnectionUseCase(repository: repository, drives: drives.service)
                .execute(draft.connection, credentials: repository.credentials(for: draft.credentialsSource))

            #expect(saved.count == 2)
            #expect(try repository.all().first { $0.id == original.id } == original)
        }
    }

    @Test func activeDriveCannotBeDeleted() async throws {
        try await withWorkflowFixture { repository, drives, connection in
            try repository.save(connection, credentials: Credentials.s3())
            try Data().write(to: drives.paths.socket(connection))
            await #expect(throws: AppError.self) {
                _ = try await DeleteConnectionUseCase(repository: repository, drives: drives.service).execute(connection)
            }
            #expect(try repository.all() == [connection])
        }
    }

    @Test func deletingTheLastDriveOnAServerForgetsItsKey() async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let knownHosts = drives.paths.support.appending(path: "known_hosts")
            let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILJkXRt3/O+0kRoTjuNk0ZipZ0gJOFlaqbU46bIXehpe\n"
            let other = "other.example.com " + key
            try Data(("files.example.com " + key + other).utf8).write(to: knownHosts)
            let drive = Connection.sftp()
            let sibling = Connection.sftp(name: "Sibling")
            try repository.save(drive, credentials: Credentials(password: "secret"))
            try repository.save(sibling, credentials: Credentials(password: "secret"))
            let delete = DeleteConnectionUseCase(repository: repository, drives: drives.service)

            _ = try await delete.execute(drive)
            #expect(try String(contentsOf: knownHosts, encoding: .utf8) == "files.example.com " + key + other)

            _ = try await delete.execute(sibling)
            #expect(try String(contentsOf: knownHosts, encoding: .utf8) == other)
            #expect(!FileManager.default.fileExists(atPath: drives.paths.support.appending(path: "known_hosts.old").path))
        }
    }

    @Test func deletingADriveRemovesOnlyItsCacheAndKeepsTheDriveWhenTheCacheStays() async throws {
        try await withWorkflowFixture { repository, drives, connection in
            let sibling = Connection.s3(name: "Sibling")
            for drive in [connection, sibling] {
                try repository.save(drive, credentials: Credentials.s3())
                try FileManager.default.createDirectory(at: drives.paths.cache(drive).appending(path: "vfs"), withIntermediateDirectories: true)
            }
            let locked = drives.paths.cache(connection).appending(path: "vfs")
            try Data().write(to: locked.appending(path: "photo.jpg"))
            try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: locked.path)
            let delete = DeleteConnectionUseCase(repository: repository, drives: drives.service)

            await #expect(throws: (any Error).self) { _ = try await delete.execute(connection) }
            #expect(try repository.all().count == 2)

            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: locked.path)
            let remaining = try await delete.execute(connection)

            #expect(remaining == [sibling])
            #expect(!FileManager.default.fileExists(atPath: drives.paths.cache(connection).path))
            #expect(FileManager.default.fileExists(atPath: drives.paths.cache(sibling).path))
        }
    }

    @Test func sharingReportsTheFileOutsideADrive() async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let file = drives.paths.support.appending(path: "outside.jpg")
            await #expect {
                _ = try await ShareFilesUseCase(repository: repository, drives: drives.service).execute([file], expiry: .day)
            } throws: { error in
                (error as? FileActionError)?.file == file
            }
        }
    }

    @Test(arguments: [Connection.sftp(), Connection.gcs(), Connection.googleDrive()])
    func sharingIsUnsupportedBeforeCredentialsAreLoaded(connection: Connection) async throws {
        try await withWorkflowFixture { _, drives, _ in
            let repository = SavedConnectionRepository(
                store: ConnectionStore(url: drives.paths.config), credentials: MemoryCredentialStorage(readError: AppError("Keychain unavailable")),
            )
            try repository.save(connection, credentials: Credentials(password: "secret", serviceAccountKey: serviceAccountJSON))
            let file = drives.paths.mount(connection).appending(path: "plan.pdf")
            await #expect {
                _ = try await ShareFilesUseCase(repository: repository, drives: drives.service).execute([file], expiry: .day)
            } throws: { error in
                let message = error.localizedDescription
                return (error as? FileActionError)?.file == file && message.contains(connection.provider.title) && !message.contains("Keychain")
            }
        }
    }

    @Test func duplicatingReportsTheFileOutsideADrive() async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let file = drives.paths.support.appending(path: "outside.jpg")
            await #expect {
                _ = try await DuplicateFilesUseCase(repository: repository, drives: drives.service).execute([file])
            } throws: { error in
                (error as? FileActionError)?.file == file
            }
        }
    }

    @Test(arguments: [
        (Connection.sftp(), String(localized: .serverCopyUnavailable(Connection.sftp().provider.title))),
        (Connection.s3(name: "Archive") { $0.readOnly = true }, String(localized: .driveIsReadOnly)),
    ])
    func duplicatingRefusesTheSelectionBeforeCopyingAnyFile(refused: Connection, message: String) async throws {
        try await withWorkflowFixture { repository, drives, writable in
            let credentials = Credentials(accessKey: "key", secretKey: "secret", password: "secret")
            try repository.save(writable, credentials: credentials)
            try repository.save(refused, credentials: credentials)
            let file = drives.paths.mount(refused).appending(path: "plan.pdf")
            await #expect {
                _ = try await DuplicateFilesUseCase(repository: repository, drives: drives.service)
                    .execute([drives.paths.mount(writable).appending(path: "report.pdf"), file])
            } throws: { error in
                (error as? FileActionError)?.file == file && error.localizedDescription == message
            }
        }
    }

    @Test(arguments: [false, true])
    func quitOffersDisconnectOnlyForActiveDrives(active: Bool) async throws {
        try await withWorkflowFixture { _, drives, connection in
            if active { try Data().write(to: drives.paths.socket(connection)) }
            let decision = await QuitUseCase(drives: drives.service).execute(connections: [connection], operationInProgress: false)
            #expect(decision == (active ? .disconnect : .quit))
        }
    }

    @Test func quitWaitsForTheCurrentOperation() async throws {
        try await withWorkflowFixture { _, drives, _ in
            let decision = await QuitUseCase(drives: drives.service).execute(connections: [], operationInProgress: true)
            #expect(decision == .wait(String(localized: .waitBeforeQuitting)))
        }
    }
}

enum LockedChange: CaseIterable, Sendable {
    case sftpFolder, backend, encryption, encryptionPassword

    struct Drive {
        let saved: Connection
        let savedCredentials: Credentials
        let edited: Connection
        let editedCredentials: Credentials
    }

    var drive: Drive {
        let server = Connection.sftp { $0.encrypted = self == .encryptionPassword }
        let bucket = Connection.s3()
        switch self {
        case .sftpFolder:
            var edited = server
            edited.sftp.remotePath = "/elsewhere"
            return Drive(saved: server, savedCredentials: Credentials(password: "secret"), edited: edited, editedCredentials: Credentials(password: "secret"))
        case .backend:
            let edited = Connection.sftp(name: bucket.name) { $0.id = bucket.id }
            return Drive(saved: bucket, savedCredentials: .s3(), edited: edited, editedCredentials: Credentials(password: "secret"))
        case .encryption:
            var edited = bucket
            edited.encrypted = true
            return Drive(
                saved: bucket, savedCredentials: .s3(), edited: edited,
                editedCredentials: Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "new"),
            )
        case .encryptionPassword:
            return Drive(
                saved: server, savedCredentials: Credentials(encryptionPassword: "original", password: "secret"), edited: server,
                editedCredentials: Credentials(encryptionPassword: "changed", password: "secret"),
            )
        }
    }
}

private func withWorkflowFixture(
    operation: (SavedConnectionRepository, StubbedDrives, Connection) async throws -> Void,
) async throws {
    let drives = try StubbedDrives("workflow")
    defer { drives.remove() }
    let repository = SavedConnectionRepository(store: ConnectionStore(url: drives.paths.config), credentials: MemoryCredentialStorage())
    try await operation(repository, drives, Connection.s3())
}

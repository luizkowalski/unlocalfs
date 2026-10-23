import Foundation
import Testing
@testable import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSTestSupport

@Suite struct WorkflowTests {
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

    @Test(arguments: redirections)
    func savedSFTPDriveCannotBeRedirected(change: Redirection) async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let connection = Connection.sftp()
            let credentials = Credentials(password: "secret")
            try repository.save(connection, credentials: credentials)
            var edited = connection
            change(&edited)
            edited.endpoint = "https://s3.example.com"
            edited.bucket = "my-bucket"
            await #expect(throws: AppError.self) {
                _ = try await SaveConnectionUseCase(repository: repository, drives: drives.service)
                    .execute(edited, credentials: Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "pw", password: "secret"), confirmation: "pw")
            }
            #expect(try repository.all() == [connection])
            #expect(try repository.credentials(for: connection.id) == credentials)
        }
    }

    @Test func savedS3DriveCannotBecomeSFTP() async throws {
        try await withWorkflowFixture { repository, drives, connection in
            try repository.save(connection, credentials: Credentials.s3())
            let edited = Connection.sftp(name: connection.name) { $0.id = connection.id }
            await #expect(throws: AppError.self) {
                _ = try await SaveConnectionUseCase(repository: repository, drives: drives.service)
                    .execute(edited, credentials: Credentials(password: "secret"))
            }
            #expect(try repository.all() == [connection])
        }
    }

    @Test func savedEncryptedSFTPDriveKeepsItsEncryptionPassword() async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let connection = Connection.sftp { $0.encrypted = true }
            try repository.save(connection, credentials: Credentials(encryptionPassword: "original", password: "secret"))
            await #expect(throws: AppError.self) {
                _ = try await SaveConnectionUseCase(repository: repository, drives: drives.service)
                    .execute(connection, credentials: Credentials(encryptionPassword: "changed", password: "secret"))
            }
            #expect(try repository.credentials(for: connection.id).encryptionPassword == "original")
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

    @Test(arguments: [SFTPAuthentication.password, .privateKey, .agent])
    func savingKeepsOnlyTheSecretsOfTheSelectedAuthentication(authentication: SFTPAuthentication) async throws {
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
                    password: "ssh", keyPassphrase: "phrase"))
            let saved = try repository.credentials(for: connection.id)
            #expect(saved == Credentials(
                encryptionPassword: "crypt", password: authentication == .password ? "ssh" : "",
                keyPassphrase: authentication == .privateKey ? "phrase" : ""))
        }
    }

    @Test func duplicatingASFTPDriveAllowsANewFolderUnderANewIdentity() async throws {
        try await withWorkflowFixture { repository, drives, _ in
            let original = Connection.sftp()
            try repository.save(original, credentials: Credentials(password: "secret"))
            let cache = drives.paths.cache(original).appending(path: "file.txt")
            try FileManager.default.createDirectory(at: cache.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("cached".utf8).write(to: cache)
            var draft = ConnectionDraft(duplicating: original)
            draft.connection.sftp.remotePath = "/elsewhere"

            let saved = try await SaveConnectionUseCase(repository: repository, drives: drives.service)
                .execute(draft.connection, credentials: repository.credentials(for: draft.credentialsSource))

            #expect(saved.count == 2)
            #expect(try repository.all().first { $0.id == original.id } == original)
            #expect(!FileManager.default.fileExists(atPath: drives.paths.cache(draft.connection).path))
            #expect(try String(contentsOf: cache, encoding: .utf8) == "cached")
        }
    }

    @Test func automaticConnectSavesAndKeepsTheCredentials() async throws {
        try await withWorkflowFixture { repository, _, connection in
            try repository.save(connection, credentials: Credentials.s3())

            let saved = try SetAutomaticConnectUseCase(repository: repository).execute(connection, connectsAutomatically: true)

            #expect(saved.map(\.connectsAutomatically) == [true])
            #expect(try repository.all() == saved)
            #expect(try repository.credentials(for: connection.id) == Credentials.s3())
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

    @Test(arguments: [Connection.sftp(), Connection.gcs()])
    func sharingIsUnsupportedBeforeCredentialsAreLoaded(connection: Connection) async throws {
        try await withWorkflowFixture { _, drives, _ in
            let repository = SavedConnectionRepository(
                store: ConnectionStore(url: drives.paths.config), credentials: MemoryCredentialStorage(readError: AppError("Keychain unavailable")))
            try repository.save(connection, credentials: Credentials(password: "secret", serviceAccountKey: serviceAccountJSON))
            let file = drives.paths.mount(connection).appending(path: "plan.pdf")
            await #expect {
                _ = try await ShareFilesUseCase(repository: repository, drives: drives.service).execute([file], expiry: .day)
            } throws: { error in
                let message = error.localizedDescription
                return (error as? FileActionError)?.file == file && message.contains(connection.provider.title) && !message.contains("Keychain")
            }
            #expect(drives.rcloneCalls.isEmpty)
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
            #expect(drives.rcloneCalls.isEmpty)
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

typealias Redirection = @Sendable (inout Connection) -> Void

private let redirections: [Redirection] = [
    { $0.sftp.remotePath = "/elsewhere" },
    { $0.encrypted = true },
    { $0.provider = .other },
]

private func withWorkflowFixture(
    operation: (SavedConnectionRepository, StubbedDrives, Connection) async throws -> Void
) async throws {
    let drives = try StubbedDrives("workflow")
    defer { drives.remove() }
    let repository = SavedConnectionRepository(store: ConnectionStore(url: drives.paths.config), credentials: MemoryCredentialStorage())
    try await operation(repository, drives, Connection.s3())
}

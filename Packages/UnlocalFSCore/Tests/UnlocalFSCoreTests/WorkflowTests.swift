import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite struct WorkflowTests {
    @Test func saveRejectsANameAddedAfterTheEditorOpened() async throws {
        try await withWorkflowFixture { repository, drives, paths, connection in
            let original = Credentials(accessKey: "key", secretKey: "secret")
            try repository.save(connection, credentials: original)
            let config = try Data(contentsOf: paths.config)
            var draft = connection
            draft.id = UUID()
            draft.encrypted = true
            await #expect(throws: AppError.self) {
                _ = try await SaveConnectionUseCase(repository: repository, drives: drives)
                    .execute(draft, credentials: Credentials(accessKey: "new-key", secretKey: "new-secret", encryptionPassword: "password"), confirmation: "password")
            }
            #expect(try Data(contentsOf: paths.config) == config)
            #expect(try repository.credentials(for: connection.id) == original)
            #expect(try repository.credentials(for: draft.id) == Credentials())
            #expect(!FileManager.default.fileExists(atPath: paths.support.appending(path: "process-calls").path))
        }
    }

    @Test(arguments: redirections)
    func savedSFTPDriveCannotBeRedirected(change: Redirection) async throws {
        try await withWorkflowFixture { repository, drives, _, _ in
            let connection = sftpFixture()
            let credentials = Credentials(password: "secret")
            try repository.save(connection, credentials: credentials)
            var edited = connection
            change(&edited)
            edited.endpoint = "https://s3.example.com"
            edited.bucket = "my-bucket"
            await #expect(throws: AppError.self) {
                _ = try await SaveConnectionUseCase(repository: repository, drives: drives)
                    .execute(edited, credentials: Credentials(accessKey: "key", secretKey: "secret", encryptionPassword: "pw", password: "secret"), confirmation: "pw")
            }
            #expect(try repository.all() == [connection])
            #expect(try repository.credentials(for: connection.id) == credentials)
        }
    }

    @Test func savedS3DriveCannotBecomeSFTP() async throws {
        try await withWorkflowFixture { repository, drives, _, connection in
            try repository.save(connection, credentials: Credentials(accessKey: "key", secretKey: "secret"))
            var edited = sftpFixture(name: connection.name)
            edited.id = connection.id
            await #expect(throws: AppError.self) {
                _ = try await SaveConnectionUseCase(repository: repository, drives: drives)
                    .execute(edited, credentials: Credentials(password: "secret"))
            }
            #expect(try repository.all() == [connection])
        }
    }

    @Test func savedEncryptedSFTPDriveKeepsItsEncryptionPassword() async throws {
        try await withWorkflowFixture { repository, drives, _, _ in
            var connection = sftpFixture()
            connection.encrypted = true
            try repository.save(connection, credentials: Credentials(encryptionPassword: "original", password: "secret"))
            await #expect(throws: AppError.self) {
                _ = try await SaveConnectionUseCase(repository: repository, drives: drives)
                    .execute(connection, credentials: Credentials(encryptionPassword: "changed", password: "secret"))
            }
            #expect(try repository.credentials(for: connection.id).encryptionPassword == "original")
        }
    }

    @Test func savedSFTPDriveKeepsEditingHostPortAndUsername() async throws {
        try await withWorkflowFixture { repository, drives, _, _ in
            var connection = sftpFixture()
            try repository.save(connection, credentials: Credentials(password: "secret"))
            connection.sftp.host = "other.example.com"
            connection.sftp.port = 2222
            connection.sftp.username = "other"
            let saved = try await SaveConnectionUseCase(repository: repository, drives: drives)
                .execute(connection, credentials: Credentials(password: "secret"))
            #expect(saved == [connection])
        }
    }

    @Test func savedSFTPDriveKeepsEditingAuthentication() async throws {
        try await withWorkflowFixture { repository, drives, _, _ in
            var connection = sftpFixture()
            connection.encrypted = true
            try repository.save(connection, credentials: Credentials(encryptionPassword: "crypt", password: "secret"))
            connection.sftp.authentication = .privateKey
            connection.sftp.keyFile = "/Users/me/.ssh/id_ed25519"
            connection.readOnly = true
            let saved = try await SaveConnectionUseCase(repository: repository, drives: drives)
                .execute(connection, credentials: Credentials(encryptionPassword: "crypt", password: "secret", keyPassphrase: "phrase"))
            #expect(saved == [connection])
            #expect(try repository.credentials(for: connection.id) == Credentials(encryptionPassword: "crypt", keyPassphrase: "phrase"))
        }
    }

    @Test(arguments: [SFTPAuthentication.password, .privateKey, .agent])
    func savingKeepsOnlyTheSecretsOfTheSelectedAuthentication(authentication: SFTPAuthentication) async throws {
        try await withWorkflowFixture { repository, drives, _, _ in
            var connection = sftpFixture()
            connection.encrypted = true
            connection.sftp.authentication = authentication
            connection.sftp.keyFile = "/Users/me/.ssh/id_ed25519"
            try repository.save(connection, credentials: Credentials(encryptionPassword: "crypt"))
            _ = try await SaveConnectionUseCase(repository: repository, drives: drives).execute(
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
        try await withWorkflowFixture { repository, drives, paths, _ in
            let original = sftpFixture()
            try repository.save(original, credentials: Credentials(password: "secret"))
            let cache = paths.cache(original).appending(path: "file.txt")
            try FileManager.default.createDirectory(at: cache.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("cached".utf8).write(to: cache)
            var draft = ConnectionDraft(duplicating: original)
            draft.connection.sftp.remotePath = "/elsewhere"

            let saved = try await SaveConnectionUseCase(repository: repository, drives: drives)
                .execute(draft.connection, credentials: repository.credentials(for: draft.credentialsSource))

            #expect(saved.count == 2)
            #expect(try repository.all().first { $0.id == original.id } == original)
            #expect(!FileManager.default.fileExists(atPath: paths.cache(draft.connection).path))
            #expect(try String(contentsOf: cache, encoding: .utf8) == "cached")
        }
    }

    @Test func activeDriveCannotBeDeleted() async throws {
        try await withWorkflowFixture { repository, drives, paths, connection in
            try repository.save(connection, credentials: Credentials(accessKey: "key", secretKey: "secret"))
            try Data().write(to: paths.socket(connection))
            await #expect(throws: AppError.self) {
                _ = try await DeleteConnectionUseCase(repository: repository, drives: drives).execute(connection)
            }
            #expect(try repository.all() == [connection])
        }
    }

    @Test func deletingTheLastDriveOnAServerForgetsItsKey() async throws {
        try await withWorkflowFixture { repository, drives, paths, _ in
            let knownHosts = paths.support.appending(path: "known_hosts")
            let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILJkXRt3/O+0kRoTjuNk0ZipZ0gJOFlaqbU46bIXehpe\n"
            let other = "other.example.com " + key
            try Data(("files.example.com " + key + other).utf8).write(to: knownHosts)
            let drive = sftpFixture()
            let sibling = sftpFixture(name: "Sibling")
            try repository.save(drive, credentials: Credentials(password: "secret"))
            try repository.save(sibling, credentials: Credentials(password: "secret"))
            let delete = DeleteConnectionUseCase(repository: repository, drives: drives)

            _ = try await delete.execute(drive)
            #expect(try String(contentsOf: knownHosts, encoding: .utf8) == "files.example.com " + key + other)

            _ = try await delete.execute(sibling)
            #expect(try String(contentsOf: knownHosts, encoding: .utf8) == other)
            #expect(!FileManager.default.fileExists(atPath: paths.support.appending(path: "known_hosts.old").path))
        }
    }

    @Test func sharingReportsTheFileOutsideADrive() async throws {
        try await withWorkflowFixture { repository, drives, paths, _ in
            let file = paths.support.appending(path: "outside.jpg")
            await #expect {
                _ = try await ShareFilesUseCase(repository: repository, drives: drives).execute([file], expiry: .day)
            } throws: { error in
                (error as? ShareFileError)?.file == file
            }
        }
    }

    @Test(arguments: [sftpFixture(), gcsFixture()])
    func sharingIsUnsupportedBeforeCredentialsAreLoaded(connection: Connection) async throws {
        try await withWorkflowFixture { _, drives, paths, _ in
            let repository = SavedConnectionRepository(
                store: ConnectionStore(url: paths.config), credentials: MemoryCredentialStorage(readError: AppError("Keychain unavailable")))
            try repository.save(connection, credentials: Credentials(password: "secret", serviceAccountKey: serviceAccountJSON))
            let file = paths.mount(connection).appending(path: "plan.pdf")
            await #expect {
                _ = try await ShareFilesUseCase(repository: repository, drives: drives).execute([file], expiry: .day)
            } throws: { error in
                let message = error.localizedDescription
                return (error as? ShareFileError)?.file == file && message.contains(connection.provider.title) && !message.contains("Keychain")
            }
            #expect(!FileManager.default.fileExists(atPath: paths.support.appending(path: "process-calls").path))
        }
    }

    @Test func quitRefusesAnActiveDrive() async throws {
        try await withWorkflowFixture { _, drives, paths, connection in
            try Data().write(to: paths.socket(connection))
            await #expect(throws: AppError.self) {
                try await QuitUseCase(drives: drives).execute(connections: [connection], operationInProgress: false)
            }
        }
    }

    @Test func quitWaitsForTheCurrentOperation() async throws {
        try await withWorkflowFixture { _, drives, _, _ in
            await #expect(throws: AppError.self) {
                try await QuitUseCase(drives: drives).execute(connections: [], operationInProgress: true)
            }
        }
    }
}

typealias Redirection = @Sendable (inout Connection) -> Void

private let redirections: [Redirection] = [
    { $0.sftp.remotePath = "/elsewhere" },
    { $0.encrypted = true },
    { $0.provider = .other }
]

private func withWorkflowFixture(
    operation: (SavedConnectionRepository, MountService, AppPaths, Connection) async throws -> Void
) async throws {
    let root = FileManager.default.temporaryDirectory.appending(path: "uf-workflow-\(UUID())")
    defer { try? FileManager.default.removeItem(at: root) }
    let paths = AppPaths(config: root.appending(path: "config.json"), support: root, mounts: root.appending(path: "drives"), logs: root.appending(path: "logs"))
    try paths.prepare()
    let executable = root.appending(path: "rclone")
    try writeRcloneStub("""
    printf '%s\\n' "$1" >> '\(root.path)/process-calls'
    if [ "$1" = 'rc' ]; then printf '%s' '\(statusBatch(cache: #""uploadsQueued":1,"uploadsInProgress":0,"erroredFiles":0,"bytesUsed":0"#))'; fi
    """, to: executable)
    let repository = SavedConnectionRepository(store: ConnectionStore(url: paths.config), credentials: MemoryCredentialStorage())
    let drives = MountService(executable: executable, helperDirectory: root, paths: paths)
    try await operation(repository, drives, paths, fixture())
}

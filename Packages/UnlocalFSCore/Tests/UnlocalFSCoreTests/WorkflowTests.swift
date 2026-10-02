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
            #expect(try repository.all() == [connection])
            #expect(try Data(contentsOf: paths.config) == config)
            #expect(try repository.credentials(for: connection.id) == original)
            #expect(try repository.credentials(for: draft.id) == Credentials())
            #expect(!FileManager.default.fileExists(atPath: paths.support.appending(path: "process-calls").path))
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

    @Test func toggleKeepsQueuedUploadsRunning() async throws {
        try await withWorkflowFixture { repository, drives, paths, connection in
            try Data().write(to: paths.socket(connection))
            await #expect(throws: UploadsPendingError.self) {
                _ = try await ToggleDriveUseCase(repository: repository, drives: drives).execute(connection)
            }
            #expect(await drives.status(connection).isActive)
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

private func withWorkflowFixture(
    operation: (SavedConnectionRepository, MountService, AppPaths, Connection) async throws -> Void
) async throws {
    let root = FileManager.default.temporaryDirectory.appending(path: "uf-workflow-\(UUID())")
    defer { try? FileManager.default.removeItem(at: root) }
    let paths = AppPaths(config: root.appending(path: "config.json"), support: root, mounts: root.appending(path: "drives"), logs: root.appending(path: "logs"))
    try paths.prepare()
    let executable = root.appending(path: "rclone")
    try """
    #!/bin/sh
    printf '%s\\n' "$1" >> '\(root.path)/process-calls'
    if [ "$4" = 'vfs/queue' ]; then printf '{"queue":[]}'; exit 0; fi
    if [ "$1" = 'rc' ]; then printf '%s' '{"diskCache":{"uploadsQueued":1,"uploadsInProgress":0,"erroredFiles":0,"bytesUsed":0}}'; fi
    """.write(to: executable, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
    let repository = SavedConnectionRepository(store: ConnectionStore(url: paths.config), credentials: MemoryCredentialStorage())
    let drives = MountService(executable: executable, helperDirectory: root, paths: paths)
    try await operation(repository, drives, paths, fixture())
}

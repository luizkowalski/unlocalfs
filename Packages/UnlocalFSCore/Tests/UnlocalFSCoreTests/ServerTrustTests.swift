import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

extension IntegrationTests {
    @Suite
    struct ServerTrustTests {
        @Test func canceledAndStaleApprovalsDoNotTrustTheKeyAndAcceptedKeysSurviveRestart() async throws {
            try await withSFTPDrive(trusted: false) { drive, sftp in
                let credentials = sftp.credentials(.password)
                let canceled = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                let fingerprint = try await Command.run(URL(filePath: "/usr/bin/ssh-keygen"), ["-lf", sftp.keys.appending(path: "host.pub").path])
                let expected = try #require(String(decoding: fingerprint, as: UTF8.self).split(separator: " ").dropFirst().first)
                #expect(canceled.fingerprints.contains(expected))
                #expect(!canceled.keyChanged)
                await drive.service.cancelServerTrust(canceled)
                await #expect(throws: AppError.self) { try await drive.service.trustServer(canceled) }
                #expect(try Data(contentsOf: drive.knownHosts).isEmpty)
                await #expect(throws: ServerTrustChallenge.self) { try await drive.service.test(drive.connection, credentials: credentials) }

                let first = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                let stale = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                try await drive.service.trustServer(first)
                let trusted = try Data(contentsOf: drive.knownHosts)
                await #expect(throws: AppError.self) { try await drive.service.trustServer(stale) }
                #expect(try Data(contentsOf: drive.knownHosts) == trusted)
                try await drive.reopen().test(drive.connection, credentials: credentials)
                let permissions = try FileManager.default.attributesOfItem(atPath: drive.knownHosts.path)[.posixPermissions] as? Int
                #expect(permissions == 0o600)
            }
        }

        @Test func changedKeysRequireApprovalAndReplaceOnlyThatServer() async throws {
            try await withSFTPDrive { drive, sftp in
                let credentials = sftp.credentials(.password)
                let other = sftp.knownHostsEntry.replacingOccurrences(of: "[127.0.0.1]:\(sftp.port)", with: "other.example.com")
                try Data((sftp.knownHostsEntry + other).utf8).write(to: drive.knownHosts)
                let before = try Data(contentsOf: drive.knownHosts)
                try await sftp.restartServer(hostKey: "other-host")

                let challenge = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                #expect(challenge.keyChanged)
                #expect(try Data(contentsOf: drive.knownHosts) == before)
                await #expect(throws: ServerTrustChallenge.self) { try await drive.service.mount(drive.connection, credentials: credentials) }
                try await drive.service.trustServer(challenge)
                try await drive.service.test(drive.connection, credentials: credentials)
                let hosts = try String(contentsOf: drive.knownHosts, encoding: .utf8)
                #expect(hosts.contains(other))
                #expect(!hosts.contains(sftp.knownHostsEntry))

                try await sftp.restartServer(hostKey: "third-host")
                let reviewed = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                try await sftp.restartServer(hostKey: "other-host")
                try await drive.service.trustServer(reviewed)
                let replacement = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                #expect(replacement.keyChanged)
                #expect(replacement.fingerprints != reviewed.fingerprints, "a server that changes after review still fails verification")
            }
        }

        @Test func revokedServerKeyCannotBeAcceptedThroughThePrompt() async throws {
            try await withSFTPDrive { drive, sftp in
                let revoked = "@revoked " + sftp.knownHostsEntry
                try revoked.write(to: drive.knownHosts, atomically: true, encoding: .utf8)
                await #expect {
                    try await drive.service.test(drive.connection, credentials: sftp.credentials(.password))
                } throws: { !($0 is ServerTrustChallenge) }
                #expect(try String(contentsOf: drive.knownHosts, encoding: .utf8) == revoked)
            }
        }

        @Test func deletingDrivesForgetsAServerKeyWithItsLastDrive() async throws {
            try await withSFTPDrive { drive, sftp in
                let credentials = sftp.credentials(.password)
                let other = sftp.knownHostsEntry.replacingOccurrences(of: "[127.0.0.1]:\(sftp.port)", with: "other.example.com")
                try Data((sftp.knownHostsEntry + other).utf8).write(to: drive.knownHosts)
                var sibling = drive.connection
                sibling.id = UUID()
                sibling.name = "Sibling"
                let repository = try repository(saving: drive.connection, sibling, on: drive, credentials: credentials)
                let delete = DeleteConnectionUseCase(repository: repository, drives: drive.service)

                _ = try await delete.execute(drive.connection)
                try await drive.service.test(sibling, credentials: credentials)

                _ = try await delete.execute(sibling)
                #expect(try String(contentsOf: drive.knownHosts, encoding: .utf8) == other)
                #expect(try !FileManager.default.contentsOfDirectory(atPath: drive.paths.support.path).contains("known_hosts.old"))
                await #expect(throws: ServerTrustChallenge.self) { try await drive.service.test(drive.connection, credentials: credentials) }
            }
        }

        @MainActor @Test func editorCanCancelTrustAndThenTrustTheKeyAndRetryTheConnectionTest() async throws {
            try await withUntrustedServerApp { drive, connection, app, repository in
                let editor = editor(for: connection, drive: drive, app: app, repository: repository)
                await editor.test()
                #expect(editor.serverTrust != nil)
                #expect(!editor.tested)
                #expect(editor.error == nil)
                await editor.cancelServerTrust()
                #expect(editor.serverTrust == nil)
                #expect(!editor.tested)
                #expect(!editor.isLocked)

                await editor.test()
                #expect(editor.serverTrust != nil)
                await editor.trustServer()
                #expect(editor.serverTrust == nil)
                #expect(editor.tested)
                #expect(editor.error == nil)
            }
        }

        @MainActor @Test func connectingAnUntrustedServerSelectsItsPromptAndTrustingConnectsTheDrive() async throws {
            try await withUntrustedServerApp { _, connection, app, _ in
                await app.refresh()
                for _ in 0..<2 {
                    app.selection = nil
                    await app.toggle(connection)
                    #expect(app.serverTrust[connection.id] != nil)
                    #expect(app.selection == connection.id)
                }

                await app.trustServer(connection)
                #expect(app.serverTrust[connection.id] == nil)
                #expect(app.errors[connection.id] == nil)
                #expect(app.isActive(connection))
                await app.toggle(connection)
            }
        }

        private func challengeFor(_ connection: Connection, on service: MountService, credentials: Credentials) async throws -> ServerTrustChallenge {
            do {
                try await service.test(connection, credentials: credentials)
                throw AppError("Expected a server trust challenge")
            } catch let challenge as ServerTrustChallenge { return challenge }
        }

        private func repository(saving connections: Connection..., on drive: Drive, credentials: Credentials) throws -> SavedConnectionRepository {
            let repository = SavedConnectionRepository(store: ConnectionStore(url: drive.paths.config), credentials: MemoryCredentialStorage())
            for connection in connections { try repository.save(connection, credentials: credentials) }
            return repository
        }

        @MainActor private func editor(
            for connection: Connection, drive: Drive, app: AppViewModel, repository: SavedConnectionRepository
        ) -> ConnectionEditorViewModel {
            let factory = ViewModelFactory(app: app, repository: repository, drives: drive.service,
                                           saveConnection: SaveConnectionUseCase(repository: repository, drives: drive.service))
            let editor = factory.makeEditor(ConnectionDraft(connection: connection))
            editor.loadCredentials()
            return editor
        }

        private func withUntrustedServerApp(
            _ body: @MainActor @Sendable (Drive, Connection, AppViewModel, SavedConnectionRepository) async throws -> Void
        ) async throws {
            try await withSFTPDrive(trusted: false) { drive, sftp in
                let connection = drive.connection
                let repository = try repository(saving: connection, on: drive, credentials: sftp.credentials(.password))
                let app = await AppViewModel(
                    initialConnections: .success([connection]), drives: drive.service,
                    deleteConnection: DeleteConnectionUseCase(repository: repository, drives: drive.service),
                    toggleDrive: ToggleDriveUseCase(repository: repository, drives: drive.service),
                    shareFiles: ShareFilesUseCase(repository: repository, drives: drive.service),
                    exportConfig: ExportRcloneConfigUseCase(repository: repository, drives: drive.service),
                    quit: QuitUseCase(drives: drive.service), desktop: DriveDesktopServices(paths: drive.paths)
                )
                try await body(drive, connection, app, repository)
            }
        }
    }
}

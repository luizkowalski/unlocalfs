import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

extension IntegrationTests {
    @Suite
    struct ServerTrustTests {
        @Test func acceptedKeyIsRememberedAfterRestart() async throws {
            try await withSFTPDrive(trusted: false) { drive, sftp in
                let credentials = sftp.credentials(.password)
                let challenge = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                let fingerprint = try await Command.run(URL(filePath: "/usr/bin/ssh-keygen"), ["-lf", sftp.keys.appending(path: "host.pub").path])
                let expected = try #require(String(decoding: fingerprint, as: UTF8.self).split(separator: " ").dropFirst().first)
                #expect(challenge.fingerprints.contains(expected))
                #expect(!challenge.keyChanged)
                try await drive.service.trustServer(challenge)

                try await drive.reopen().test(drive.connection, credentials: credentials)
                let permissions = try FileManager.default.attributesOfItem(atPath: drive.knownHosts.path)[.posixPermissions] as? Int
                #expect(permissions == 0o600)
            }
        }

        @Test func changedKeyRequiresApprovalAndReplacesOnlyThatServer() async throws {
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
            }
        }

        @Test func cancelingTrustDoesNotAcceptTheKey() async throws {
            try await withSFTPDrive(trusted: false) { drive, sftp in
                let credentials = sftp.credentials(.password)
                let challenge = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                await drive.service.cancelServerTrust(challenge)
                await #expect(throws: AppError.self) { try await drive.service.trustServer(challenge) }
                #expect(try Data(contentsOf: drive.knownHosts).isEmpty)
                await #expect(throws: ServerTrustChallenge.self) { try await drive.service.test(drive.connection, credentials: credentials) }
            }
        }

        @Test func serverChangingAfterReviewStillFailsVerification() async throws {
            try await withSFTPDrive(trusted: false) { drive, sftp in
                let credentials = sftp.credentials(.password)
                let challenge = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                try await sftp.restartServer(hostKey: "other-host")
                try await drive.service.trustServer(challenge)
                let replacement = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                #expect(replacement.keyChanged)
                #expect(replacement.fingerprints != challenge.fingerprints)
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

        @Test func staleApprovalDoesNotOverwriteNewerTrust() async throws {
            try await withSFTPDrive(trusted: false) { drive, sftp in
                let credentials = sftp.credentials(.password)
                let first = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                let stale = try await challengeFor(drive.connection, on: drive.service, credentials: credentials)
                try await drive.service.trustServer(first)
                let before = try Data(contentsOf: drive.knownHosts)
                await #expect(throws: AppError.self) { try await drive.service.trustServer(stale) }
                #expect(try Data(contentsOf: drive.knownHosts) == before)
                try await drive.service.test(drive.connection, credentials: credentials)
            }
        }

        @Test func deletingTheLastDriveOnAServerForgetsItsKey() async throws {
            try await withSFTPDrive { drive, sftp in
                let credentials = sftp.credentials(.password)
                let other = sftp.knownHostsEntry.replacingOccurrences(of: "[127.0.0.1]:\(sftp.port)", with: "other.example.com")
                try Data((sftp.knownHostsEntry + other).utf8).write(to: drive.knownHosts)
                let repository = try repository(saving: drive.connection, on: drive, credentials: credentials)

                _ = try await DeleteConnectionUseCase(repository: repository, drives: drive.service).execute(drive.connection)

                #expect(try String(contentsOf: drive.knownHosts, encoding: .utf8) == other)
                #expect(try !FileManager.default.contentsOfDirectory(atPath: drive.paths.support.path).contains("known_hosts.old"))
                await #expect(throws: ServerTrustChallenge.self) { try await drive.service.test(drive.connection, credentials: credentials) }
            }
        }

        @Test func deletingOneOfTwoDrivesOnAServerKeepsItsKey() async throws {
            try await withSFTPDrive { drive, sftp in
                let credentials = sftp.credentials(.password)
                var sibling = drive.connection
                sibling.id = UUID()
                sibling.name = "Sibling"
                let repository = try repository(saving: drive.connection, sibling, on: drive, credentials: credentials)

                _ = try await DeleteConnectionUseCase(repository: repository, drives: drive.service).execute(drive.connection)

                try await drive.service.test(sibling, credentials: credentials)
            }
        }

        @MainActor @Test func editorTrustsTheKeyAndRetriesTheConnectionTest() async throws {
            try await withUntrustedServerApp { drive, connection, app, repository in
                let editor = editor(for: connection, drive: drive, app: app, repository: repository)
                await editor.test()
                #expect(editor.serverTrust != nil)
                #expect(!editor.tested)
                #expect(editor.error == nil)
                await editor.trustServer()
                #expect(editor.serverTrust == nil)
                #expect(editor.tested)
                #expect(editor.error == nil)
            }
        }

        @MainActor @Test func cancelingEditorTrustLeavesTheConnectionUntested() async throws {
            try await withUntrustedServerApp { drive, connection, app, repository in
                let editor = editor(for: connection, drive: drive, app: app, repository: repository)
                await editor.test()
                await editor.cancelServerTrust()
                #expect(editor.serverTrust == nil)
                #expect(!editor.tested)
                #expect(!editor.isLocked)
            }
        }

        @MainActor @Test func trustingSavedConnectionConnectsTheDrive() async throws {
            try await withUntrustedServerApp { _, connection, app, _ in
                await app.refresh()
                await app.toggle(connection)
                #expect(app.serverTrust[connection.id] != nil)
                await app.trustServer(connection)
                #expect(app.serverTrust[connection.id] == nil)
                #expect(app.errors[connection.id] == nil)
                #expect(app.isActive(connection))
                await app.toggle(connection)
            }
        }

        @MainActor @Test func connectingAnUntrustedServerSelectsItsPrompt() async throws {
            try await withUntrustedServerApp { _, connection, app, _ in
                await app.refresh()
                app.selection = nil
                await app.toggle(connection)
                #expect(app.serverTrust[connection.id] != nil)
                #expect(app.selection == connection.id)

                app.selection = nil
                await app.toggle(connection)
                #expect(app.serverTrust[connection.id] != nil)
                #expect(app.selection == connection.id)
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

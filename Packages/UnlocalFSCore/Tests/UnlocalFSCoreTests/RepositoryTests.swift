import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite struct RepositoryTests {
    @Test func concurrentSavesKeepEveryConnection() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "uf-repository-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SavedConnectionRepository(store: ConnectionStore(url: root.appending(path: "config.json")), credentials: MemoryCredentialStorage())
        let connections = (0..<40).map { fixture(name: "Drive \($0)") }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for connection in connections {
                group.addTask { try repository.save(connection, credentials: Credentials(accessKey: "key", secretKey: "secret")) }
            }
            try await group.waitForAll()
        }

        #expect(Set(try repository.all().map(\.id)) == Set(connections.map(\.id)))
    }

    @Test(arguments: [
        (Provider.sftp, Credentials(password: "hunter2-password", keyPassphrase: "hunter2-passphrase"), "hunter2"),
        (.googleCloudStorage, Credentials(serviceAccountKey: serviceAccountJSON), "BEGIN PRIVATE KEY")
    ])
    func savedSettingsAndSecretsSurviveReopening(provider: Provider, credentials: Credentials, secret: String) throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "uf-repository-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "config.json")
        let service = "app.unlocalfs.tests.\(UUID())"
        let keychain = Keychain(service: service)
        var connection = provider == .sftp ? sftpFixture() : gcsFixture()
        connection.folder = "clients/acme"
        if provider == .sftp {
            connection.sftp.port = 2222
            connection.sftp.remotePath = "/srv/files"
            connection.sftp.authentication = .privateKey
            connection.sftp.keyFile = "/Users/me/.ssh/id_ed25519"
            connection.sftp.agentSocket = "/tmp/agent.sock"
        }
        defer { try? keychain.delete(connection.id) }
        let repository = SavedConnectionRepository(store: ConnectionStore(url: url), credentials: keychain)
        try repository.save(connection, credentials: credentials)

        let reopened = SavedConnectionRepository(store: ConnectionStore(url: url), credentials: Keychain(service: service))
        #expect(try reopened.all() == [connection])
        #expect(try reopened.credentials(for: connection.id) == credentials)
        #expect(try !String(contentsOf: url, encoding: .utf8).contains(secret))
    }

    @Test(arguments: [false, true])
    func failedCredentialWriteRestoresThePreviousConfig(updating: Bool) throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "uf-repository-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "config.json")
        let store = ConnectionStore(url: url)
        let unrelated = fixture(name: "Other files")
        try store.save(unrelated)
        let original = fixture()
        if updating { try store.save(original) }
        let previous = updating ? [original, unrelated] : [unrelated]
        var edited = original
        edited.folder = "new-folder"
        let repository = SavedConnectionRepository(store: store, credentials: UnavailableCredentialStorage())

        #expect(throws: AppError.self) {
            try repository.save(edited, credentials: Credentials(accessKey: "key", secretKey: "secret"))
        }

        #expect(try ConnectionStore(url: url).all() == previous)
    }

    @Test func failedConfigWriteKeepsTheCredentials() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "uf-repository-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let credentials = Credentials(accessKey: "key", secretKey: "secret")
        let repository = SavedConnectionRepository(store: ConnectionStore(url: root.appending(path: "config.json")), credentials: MemoryCredentialStorage())
        let connection = fixture()
        try repository.save(connection, credentials: credentials)
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: root.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: root.path) }

        #expect(throws: (any Error).self) { try repository.delete(connection.id) }

        #expect(try repository.all() == [connection])
        #expect(try repository.credentials(for: connection.id) == credentials)
    }
}

final class MemoryCredentialStorage: CredentialStorage {
    private let items = Mutex<[UUID: Credentials]>([:])

    private let readError: AppError?

    init(readError: AppError? = nil) { self.readError = readError }

    func read(_ id: UUID) throws -> Credentials? {
        if let readError { throw readError }
        return items.withLock { $0[id] }
    }
    func save(_ credentials: Credentials, for id: UUID) throws { items.withLock { $0[id] = credentials } }
    func delete(_ id: UUID) throws { items.withLock { $0[id] = nil } }
}

private struct UnavailableCredentialStorage: CredentialStorage {
    func read(_ id: UUID) throws -> Credentials? { nil }
    func save(_ credentials: Credentials, for id: UUID) throws { throw AppError("Keychain unavailable") }
    func delete(_ id: UUID) throws { throw AppError("Keychain unavailable") }
}

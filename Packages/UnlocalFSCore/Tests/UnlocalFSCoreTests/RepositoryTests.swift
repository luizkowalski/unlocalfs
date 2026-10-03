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

    @Test func failedCredentialWriteRestoresTheSavedConnection() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "uf-repository-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ConnectionStore(url: root.appending(path: "config.json"))
        let original = fixture()
        try store.save(original)
        var edited = original
        edited.folder = "new-folder"
        let repository = SavedConnectionRepository(store: store, credentials: UnavailableCredentialStorage())

        #expect(throws: AppError.self) {
            try repository.save(edited, credentials: Credentials(accessKey: "key", secretKey: "secret"))
        }

        #expect(try store.all() == [original])
    }

    @Test func failedCredentialWriteDoesNotLeaveANewConnection() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "uf-repository-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ConnectionStore(url: root.appending(path: "config.json"))
        let repository = SavedConnectionRepository(store: store, credentials: UnavailableCredentialStorage())

        #expect(throws: AppError.self) {
            try repository.save(fixture(), credentials: Credentials(accessKey: "key", secretKey: "secret"))
        }

        #expect(try store.all().isEmpty)
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

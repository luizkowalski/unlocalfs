import Foundation
import Synchronization
import UnlocalFSDomain

public protocol CredentialStorage: Sendable {
    func read(_ id: UUID) throws -> Credentials?
    func save(_ credentials: Credentials, for id: UUID) throws
    func delete(_ id: UUID) throws
}

public final class SavedConnectionRepository: ConnectionRepository {
    private let store: Mutex<ConnectionStore>
    private let credentials: any CredentialStorage

    public init(store: ConnectionStore, credentials: any CredentialStorage) {
        self.store = Mutex(store)
        self.credentials = credentials
    }

    public func all() throws -> [Connection] {
        try store.withLock { try $0.all() }
    }

    public func credentials(for id: UUID) throws -> Credentials {
        try store.withLock { _ in try credentials.read(id) ?? Credentials() }
    }

    public func save(_ connection: Connection, credentials: Credentials) throws {
        try store.withLock { store in
            let previous = try store.all().first { $0.id == connection.id }
            try store.save(connection)
            do {
                try self.credentials.save(credentials, for: connection.id)
            } catch {
                if let previous {
                    try store.save(previous)
                } else {
                    try store.delete(connection.id)
                }
                throw error
            }
        }
    }

    public func delete(_ id: UUID) throws {
        try store.withLock { store in
            try store.delete(id)
            try credentials.delete(id)
        }
    }
}

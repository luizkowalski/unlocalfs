import Foundation
import Synchronization
import UnlocalFSDomain
import UnlocalFSInfrastructure

public final class MemoryCredentialStorage: CredentialStorage {
    private let items = Mutex<[UUID: Credentials]>([:])
    private let readError: AppError?

    public init(readError: AppError? = nil) { self.readError = readError }

    public func read(_ id: UUID) throws -> Credentials? {
        if let readError { throw readError }
        return items.withLock { $0[id] }
    }

    public func save(_ credentials: Credentials, for id: UUID) throws { items.withLock { $0[id] = credentials } }
    public func delete(_ id: UUID) throws { items.withLock { $0[id] = nil } }
}

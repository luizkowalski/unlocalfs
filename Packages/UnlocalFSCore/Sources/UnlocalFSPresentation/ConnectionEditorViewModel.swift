import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class ConnectionEditorViewModel {
    public var connection: Connection {
        didSet {
            if testInputs(connection) != testInputs(oldValue) || connection.sftp != oldValue.sftp { tested = false }
        }
    }
    public var credentials = Credentials() {
        didSet {
            if credentials != oldValue { tested = false }
        }
    }
    public var confirmation = ""
    public private(set) var credentialsLoaded = false
    public private(set) var testing = false
    public private(set) var saving = false
    public private(set) var tested = false
    public private(set) var error: String?
    private var showErrors = false
    public let isDuplicate: Bool
    private let credentialsSource: UUID
    public let isNew: Bool
    private let savedBackend: Backend?
    private let connections: [Connection]
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway
    private let saveConnection: SaveConnectionUseCase
    private let onSave: (Connection, [Connection]) -> Void

    init(
        draft: ConnectionDraft,
        connections: [Connection],
        repository: any ConnectionRepository,
        drives: any DriveGateway,
        saveConnection: SaveConnectionUseCase,
        onSave: @escaping (Connection, [Connection]) -> Void
    ) {
        connection = draft.connection
        credentialsSource = draft.credentialsSource
        isDuplicate = draft.isDuplicate
        isNew = !connections.contains { $0.id == draft.id }
        savedBackend = isNew || draft.isDuplicate ? nil : draft.connection.backend
        self.connections = connections
        self.repository = repository
        self.drives = drives
        self.saveConnection = saveConnection
        self.onSave = onSave
    }

    public var title: String {
        if isDuplicate { return "Duplicate connection" }
        return isNew ? "Add connection" : "Edit connection"
    }

    public var locksRemoteFolder: Bool { savedBackend?.locksFolderAfterSave ?? false }

    public var availableProviders: [Provider] {
        guard let savedBackend else { return Provider.allCases }
        return Provider.allCases.filter { $0.backend == savedBackend }
    }

    public var isLocked: Bool { testing || saving || !credentialsLoaded }

    public var fieldErrors: [ConnectionField: String] {
        guard showErrors else { return [:] }
        return connection.validate(credentials: credentials, confirmation: confirmation, against: connections).fieldErrors
    }

    public var firstInvalidField: ConnectionField? {
        let errors = fieldErrors
        return ConnectionField.allCases.first { errors[$0] != nil }
    }

    public func loadCredentials() {
        do {
            credentials = try repository.credentials(for: credentialsSource)
            confirmation = credentials.encryptionPassword
            credentialsLoaded = true
        } catch { self.error = error.localizedDescription }
    }

    public func importServiceAccountKey(_ result: Result<URL, any Error>) {
        do {
            credentials.serviceAccountKey = try ServiceAccountKey(importing: Data(contentsOf: result.get())).json
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    public func test() async {
        guard validate() else { return }
        testing = true
        tested = false
        defer { testing = false }
        do {
            try await drives.test(connection, credentials: credentials)
            tested = true
        } catch { self.error = error.localizedDescription }
    }

    public func save() async -> Bool {
        guard validate() else { return false }
        saving = true
        defer { saving = false }
        do {
            let saved = try await saveConnection.execute(connection, credentials: credentials, confirmation: confirmation)
            onSave(connection, saved)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    private func validate() -> Bool {
        showErrors = true
        error = nil
        return fieldErrors.isEmpty
    }

    private func testInputs(_ connection: Connection) -> [String] {
        [connection.provider.rawValue, connection.endpoint, connection.region, connection.bucket, connection.folder, String(connection.encrypted)]
    }
}

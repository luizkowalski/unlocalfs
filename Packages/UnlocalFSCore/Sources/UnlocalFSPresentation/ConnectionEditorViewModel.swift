import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class ConnectionEditorViewModel {
    public var connection: Connection {
        didSet {
            if connection.backend != oldValue.backend { credentials.googleSignIn = GoogleSignIn() }
        }
    }

    public var credentials = Credentials()

    public var confirmation = ""
    private var credentialsLoaded = false
    public private(set) var testing = false
    public private(set) var saving = false
    private var testedWith: (connection: Connection, credentials: Credentials)?
    public private(set) var serverTrust: ServerTrustChallenge?
    private let signIn: GoogleSignInRun
    public private(set) var error: String?
    private var showErrors = false
    private let isDuplicate: Bool
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
        onSave: @escaping (Connection, [Connection]) -> Void,
    ) {
        connection = draft.connection
        credentialsSource = draft.credentialsSource
        isDuplicate = draft.isDuplicate
        isNew = !connections.contains { $0.id == draft.id }
        savedBackend = isNew ? nil : draft.connection.backend
        self.connections = connections
        self.repository = repository
        self.drives = drives
        signIn = GoogleSignInRun(drives: drives)
        self.saveConnection = saveConnection
        self.onSave = onSave
    }

    public var title: String {
        if isDuplicate { return String(localized: .duplicateConnection) }
        return isNew ? String(localized: .addConnection) : String(localized: .editConnection)
    }

    public var locksRemoteFolder: Bool { savedBackend?.locksFolderAfterSave ?? false }

    public var availableProviders: [Provider] {
        guard let savedBackend else { return Provider.allCases }
        return Provider.allCases.filter { $0.backend == savedBackend }
    }

    public var providerSections: [[Provider]] {
        let providers = availableProviders
        return ProviderGroup.allCases.map { group in providers.filter { $0.group == group } }.filter { !$0.isEmpty }
    }

    public var initialFocus: ConnectionField? {
        guard isDuplicate, credentialsLoaded else { return nil }
        return switch connection.backend {
        case .s3Compatible, .gcs, .googleDrive: .folder
        case .sftp: .remotePath
        }
    }

    public var tested: Bool {
        testedWith.map { $0.connection.hasSameStorageSettings(as: connection) && $0.credentials == credentials } ?? false
    }

    public var isLocked: Bool { testing || saving || serverTrust != nil || !credentialsLoaded || signingIn }

    public var signingIn: Bool { signIn.isRunning }

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

    public func importServiceAccountKey(_ result: Result<URL, any Error>) async {
        do {
            let url = try result.get()
            let data = try await Task.detached { try Data(contentsOf: url) }.value
            credentials.serviceAccountKey = try ServiceAccountKey(importing: data).json
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    public func signInWithGoogle() async {
        error = nil
        guard let result = await signIn.signIn(for: connection.backend) else { return }
        do {
            credentials.googleSignIn = try result.get()
        } catch { self.error = error.localizedDescription }
    }

    public func cancelSignIn() { signIn.cancel() }

    public func test() async {
        guard validate() else { return }
        testing = true
        testedWith = nil
        defer { testing = false }
        let inputs = (connection, credentials)
        do {
            try await drives.test(inputs.0, credentials: inputs.1)
            testedWith = inputs
        } catch let challenge as ServerTrustChallenge {
            serverTrust = challenge
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

    public func trustServer() async {
        guard let challenge = serverTrust else { return }
        serverTrust = nil
        testing = true
        do {
            try await drives.trustServer(challenge)
            testing = false
            await test()
        } catch {
            testing = false
            self.error = error.localizedDescription
        }
    }

    public func cancelServerTrust() async {
        guard let challenge = serverTrust else { return }
        serverTrust = nil
        await drives.cancelServerTrust(challenge)
    }

    private func validate() -> Bool {
        showErrors = true
        error = nil
        return fieldErrors.isEmpty
    }
}

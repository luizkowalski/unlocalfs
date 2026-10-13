import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class ViewModelFactory {
    private let app: AppViewModel
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway
    private let saveConnection: SaveConnectionUseCase
    private let readServiceAccountKey: @Sendable (Result<URL, any Error>) async -> Result<Data, any Error>

    public init(
        app: AppViewModel, repository: any ConnectionRepository, drives: any DriveGateway,
        saveConnection: SaveConnectionUseCase,
        readServiceAccountKey: @escaping @Sendable (Result<URL, any Error>) async -> Result<Data, any Error>
    ) {
        self.app = app
        self.repository = repository
        self.drives = drives
        self.saveConnection = saveConnection
        self.readServiceAccountKey = readServiceAccountKey
    }

    public func makeEditor(_ draft: ConnectionDraft) -> ConnectionEditorViewModel {
        ConnectionEditorViewModel(
            draft: draft, connections: app.connections, repository: repository, drives: drives,
            saveConnection: saveConnection, onSave: app.connectionSaved, readServiceAccountKey: readServiceAccountKey
        )
    }

    public func makeActivity() -> ActivityViewModel {
        ActivityViewModel(drives: drives) { [app] in app.busy.contains($0) }
    }
}

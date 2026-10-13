import Observation
import UnlocalFSDomain

@MainActor @Observable public final class ViewModelFactory {
    private let app: AppViewModel
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway
    private let saveConnection: SaveConnectionUseCase

    public init(app: AppViewModel, repository: any ConnectionRepository, drives: any DriveGateway, saveConnection: SaveConnectionUseCase) {
        self.app = app
        self.repository = repository
        self.drives = drives
        self.saveConnection = saveConnection
    }

    public func makeEditor(_ draft: ConnectionDraft) -> ConnectionEditorViewModel {
        ConnectionEditorViewModel(
            draft: draft, connections: app.connections, repository: repository, drives: drives,
            saveConnection: saveConnection, onSave: app.connectionSaved
        )
    }

    public func makeActivity() -> ActivityViewModel {
        ActivityViewModel(drives: drives) { [app] in app.busy.contains($0) }
    }
}

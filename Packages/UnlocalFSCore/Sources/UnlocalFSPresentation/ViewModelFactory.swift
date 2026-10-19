import Observation
import UnlocalFSDomain

@MainActor @Observable public final class ViewModelFactory {
    private let app: AppViewModel
    private let repository: any ConnectionRepository
    private let drives: any DriveGateway
    private let saveConnection: SaveConnectionUseCase
    private let traffic: any TrafficRepository

    public init(
        app: AppViewModel, repository: any ConnectionRepository, drives: any DriveGateway, saveConnection: SaveConnectionUseCase,
        traffic: any TrafficRepository
    ) {
        self.app = app
        self.repository = repository
        self.drives = drives
        self.saveConnection = saveConnection
        self.traffic = traffic
    }

    public func makeEditor(_ draft: ConnectionDraft) -> ConnectionEditorViewModel {
        ConnectionEditorViewModel(
            draft: draft, connections: app.connections, repository: repository, drives: drives,
            saveConnection: saveConnection, onSave: app.connectionSaved
        )
    }

    public func makeActivity() -> ActivityViewModel {
        ActivityViewModel(drives: drives, isBusy: { [app] in app.busy.contains($0) }, recordSpeed: app.recordSpeed)
    }

    public func makeTraffic() -> TrafficViewModel {
        TrafficViewModel(repository: traffic, connections: { [app] in app.connections }, unsaved: { [app] in app.statuses.mapValues(\.unsavedTraffic) })
    }
}

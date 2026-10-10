import Foundation
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

@MainActor struct AppDependencies {
    let model: AppViewModel
    let viewModels: ViewModelFactory

    static func live() -> AppDependencies {
        let paths = AppPaths.standard
        let contents = Bundle.main.bundleURL.appending(path: "Contents")
        let drives = MountService(
            executable: contents.appending(path: "Helpers/rclone"),
            helperDirectory: contents.appending(path: "Resources/libexec"),
            paths: paths
        )
        let repository = SavedConnectionRepository(store: ConnectionStore(url: paths.config), credentials: Keychain())
        let initialConnections = Result {
            try paths.prepare()
            return try repository.all()
        }
        let model = AppViewModel(
            initialConnections: initialConnections, drives: drives,
            deleteConnection: DeleteConnectionUseCase(repository: repository, drives: drives),
            connectDrive: ConnectDriveUseCase(repository: repository, drives: drives),
            shareFiles: ShareFilesUseCase(repository: repository, drives: drives),
            duplicateFiles: DuplicateFilesUseCase(repository: repository, drives: drives),
            exportConfig: ExportRcloneConfigUseCase(repository: repository, drives: drives),
            quit: QuitUseCase(drives: drives), desktop: MacOSDesktopServices(paths: paths)
        )
        return AppDependencies(model: model, viewModels: ViewModelFactory(
            app: model, repository: repository, drives: drives, saveConnection: SaveConnectionUseCase(repository: repository, drives: drives)
        ))
    }
}

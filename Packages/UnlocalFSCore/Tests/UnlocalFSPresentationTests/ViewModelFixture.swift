import Foundation
import Synchronization
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

struct ViewModelFixture {
    let root: URL
    let paths: AppPaths
    let service: MountService
    let repository: SavedConnectionRepository

    init() throws {
        root = FileManager.default.temporaryDirectory.appending(path: "uf-view-model-\(UUID().uuidString)")
        paths = AppPaths(config: root.appending(path: "config.json"), support: root, mounts: root.appending(path: "mounts"), logs: root.appending(path: "logs"))
        try paths.prepare()
        let executable = root.appending(path: "rclone")
        try """
        #!/bin/sh
        printf '%s\\n' "$1" >> '\(root.path)/process-calls'
        case "$1" in
            lsf)
                if [ -f '\(root.path)/test-error' ]; then
                    cat '\(root.path)/test-error' >&2
                    exit 1
                fi
                ;;
            obscure) cat >/dev/null; printf 'prepared-password\\n' ;;
            rc)
                case "$4" in
                    vfs/stats) cat '\(root.path)/vfs-stats.json' ;;
                    vfs/queue) cat '\(root.path)/queue.json' ;;
                    core/stats) cat '\(root.path)/stats.json' ;;
                    *) exit 1 ;;
                esac
                ;;
            *) exit 1 ;;
        esac
        """.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        try Data(#"{"queue":[]}"#.utf8).write(to: root.appending(path: "queue.json"))
        try Data("{}".utf8).write(to: root.appending(path: "stats.json"))
        service = MountService(executable: executable, helperDirectory: root, paths: paths)
        repository = SavedConnectionRepository(store: ConnectionStore(url: paths.config), credentials: MemoryCredentialStorage())
    }

    @MainActor func app(desktop: TestDesktopServices? = nil) -> AppViewModel {
        AppViewModel(
            initialConnections: Result { try repository.all() }, drives: service,
            deleteConnection: DeleteConnectionUseCase(repository: repository, drives: service),
            toggleDrive: ToggleDriveUseCase(repository: repository, drives: service),
            shareFiles: ShareFilesUseCase(repository: repository, drives: service),
            quit: QuitUseCase(drives: service), desktop: desktop ?? TestDesktopServices(paths: paths)
        )
    }

    @MainActor func factory(_ app: AppViewModel) -> ViewModelFactory {
        ViewModelFactory(app: app, repository: repository, drives: service, saveConnection: SaveConnectionUseCase(repository: repository, drives: service))
    }

    @MainActor func editor(draft: ConnectionDraft, app: AppViewModel? = nil) -> ConnectionEditorViewModel {
        factory(app ?? self.app()).makeEditor(draft)
    }

    func serve(_ connection: Connection, queued: Int = 0, failed: Int = 0, cached: Int64 = 0) throws {
        try ConnectionStore(url: paths.config).save(connection)
        try Data().write(to: paths.socket(connection))
        let stats = #"{"diskCache":{"uploadsQueued":\#(queued),"uploadsInProgress":0,"erroredFiles":\#(failed),"bytesUsed":\#(cached)}}"#
        try Data(stats.utf8).write(to: root.appending(path: "vfs-stats.json"))
    }

    func remove() { try? FileManager.default.removeItem(at: root) }
}

func connectionFixture() -> Connection {
    var connection = Connection()
    connection.name = "My files"
    connection.endpoint = "https://s3.example.com"
    connection.bucket = "my-bucket"
    return connection
}

final class MemoryCredentialStorage: CredentialStorage {
    private let items = Mutex<[UUID: Credentials]>([:])

    func read(_ id: UUID) throws -> Credentials? { items.withLock { $0[id] } }
    func save(_ credentials: Credentials, for id: UUID) throws { items.withLock { $0[id] = credentials } }
    func delete(_ id: UUID) throws { items.withLock { $0[id] = nil } }
}

@MainActor final class TestDesktopServices: DesktopServices {
    let paths: AppPaths
    var opensAtLogin = false
    var loginError: AppError?
    var copiedLinks: [URL] = []
    var openedDrives: [UUID] = []
    struct Notification {
        let title: String
        let body: String
        let fallbackToAlert: Bool
    }
    var notifications: [Notification] = []

    init(paths: AppPaths) { self.paths = paths }

    func setOpensAtLogin(_ enabled: Bool) throws {
        if let loginError { throw loginError }
        opensAtLogin = enabled
    }

    func mountLocation(_ connection: Connection) -> URL { paths.mount(connection) }
    func cacheLocation(_ connection: Connection) -> URL { paths.cache(connection) }
    func openDrive(_ connection: Connection) { openedDrives.append(connection.id) }
    func openLog(_ connection: Connection) {}
    func copyShareLinks(_ links: [URL]) { copiedLinks = links }
    func notify(title: String, body: String, fallbackToAlert: Bool) {
        notifications.append(Notification(title: title, body: body, fallbackToAlert: fallbackToAlert))
    }
}

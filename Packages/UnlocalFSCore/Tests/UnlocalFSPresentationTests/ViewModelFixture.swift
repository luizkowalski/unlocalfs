import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation
import UnlocalFSTestSupport

struct ViewModelFixture {
    let repository: SavedConnectionRepository
    private let drives: StubbedDrives
    private let servers = ControlServers()

    var root: URL { drives.root }
    var paths: AppPaths { drives.paths }
    var service: MountService { drives.service }
    var traffic: TrafficStore { drives.traffic }
    var rcloneCalls: [String] { drives.rcloneCalls }

    init(googleClient: GoogleClient = .test) throws {
        drives = try StubbedDrives("view-model", googleClient: googleClient) { root in
            """
            case "$1" in
                lsf)
                    if [ -f '\(root.path)/test-error' ]; then
                        cat '\(root.path)/test-error' >&2
                        exit 1
                    fi
                    ;;
                obscure) printf 'prepared-password\\n' ;;
                authorize)
                    env | grep '^RCLONE_GCS_' | sort > '\(root.path)/authorize-env'
                    if [ -f '\(root.path)/authorize-hang' ]; then
                        echo $$ > '\(root.path)/authorize-pid'
                        sleep 30
                    fi
                    if [ -f '\(root.path)/authorize-error' ]; then
                        cat '\(root.path)/authorize-error'
                        exit 2
                    fi
                    printf 'NOTICE: Got code\\nPaste the following into your remote machine --->\\n%s\\n<---End paste\\n' "$(cat '\(root.path)/authorize-token')"
                    ;;
                config)
                    name="$3"
                    arguments="$*"
                    while [ $# -gt 0 ]; do
                        if [ "$1" = '--config' ]; then config="$2"; fi
                        shift
                    done
                    printf '%s' "$config" > '\(root.path)/export-config'
                    if [ "$name" = "$(cat '\(root.path)/config-error')" ]; then
                        printf 'Failed to create %s: %s' "$name" "$arguments" >&2
                        exit 1
                    fi
                    printf '[%s]\\n' "$name" >> "$config"
                    ;;
                *) exit 1 ;;
            esac
            """
        }
        repository = SavedConnectionRepository(store: ConnectionStore(url: drives.paths.config), credentials: MemoryCredentialStorage())
        try Data(#"{"queue":[]}"#.utf8).write(to: root.appending(path: "queue.json"))
        try Data(#"{\#(rcloneCounters)}"#.utf8).write(to: root.appending(path: "stats.json"))
        try Data(#"{"diskCache":{"bytesUsed":0}}"#.utf8).write(to: root.appending(path: "vfs-stats.json"))
    }

    @MainActor func app(desktop: TestDesktopServices? = nil) -> AppViewModel {
        AppViewModel(
            initialConnections: Result { try repository.all() }, drives: service,
            deleteConnection: DeleteConnectionUseCase(repository: repository, drives: service),
            setAutomaticConnect: SetAutomaticConnectUseCase(repository: repository),
            connectDrive: ConnectDriveUseCase(repository: repository, drives: service),
            signInAgain: SignInAgainUseCase(repository: repository, drives: service),
            shareFiles: ShareFilesUseCase(repository: repository, drives: service),
            duplicateFiles: DuplicateFilesUseCase(repository: repository, drives: service),
            exportConfig: ExportRcloneConfigUseCase(repository: repository, drives: service),
            quit: QuitUseCase(drives: service), desktop: desktop ?? TestDesktopServices(paths: paths),
        )
    }

    @MainActor func factory(_ app: AppViewModel) -> ViewModelFactory {
        ViewModelFactory(
            app: app, repository: repository, drives: service, saveConnection: SaveConnectionUseCase(repository: repository, drives: service), traffic: traffic,
        )
    }

    @MainActor func editor(draft: ConnectionDraft, app: AppViewModel? = nil) -> ConnectionEditorViewModel {
        factory(app ?? self.app()).makeEditor(draft)
    }

    func serve(
        _ connection: Connection, queued: Int = 0, failed: Int = 0, lastError: String? = nil, cached: Int64 = 0, downloading: Bool = false,
        downloaded: Int64 = 0,
    ) throws {
        let socket = paths.socket(connection)
        try serve(connection) { [root] request in
            if request.method == "core/quit" {
                try FileManager.default.removeItem(at: socket)
                return "{}"
            }
            guard request.method == "job/batch" else { throw ControlFailure("Unknown method \(request.method)") }
            let results = try ["vfs-stats.json", "queue.json", "stats.json"].map { try String(contentsOf: root.appending(path: $0), encoding: .utf8) }
            return #"{"results":[\#(results.joined(separator: ",")),{"transferred":[]}]}"#
        }
        try Data(#"{"diskCache":{"bytesUsed":\#(cached)}}"#.utf8).write(to: root.appending(path: "vfs-stats.json"))
        let waiting = (0 ..< queued).map { #"{"name":"queued-\#($0).txt","id":\#($0),"size":1,"expiry":5,"tries":0,"delay":5,"uploading":false}"# }
        let failing = (0 ..< failed).map { #"{"name":"failed-\#($0).txt","id":\#(queued + $0),"size":1,"expiry":30,"tries":2,"delay":10,"uploading":false}"# }
        try queue(contentsOf: waiting + failing)
        let transfers = downloading ? #"[{"name":"photo.jpg","size":1000,"bytes":100,"srcFs":":s3:bucket"}]"# : "[]"
        let error = lastError.map { #","lastError":"\#($0)""# } ?? ""
        let counters = #""bytes":\#(downloaded),"serverSideCopyBytes":0,"serverSideMoveBytes":0"#
        try Data(#"{\#(counters),"transferring":\#(transfers)\#(error)}"#.utf8).write(to: root.appending(path: "stats.json"))
        if downloaded > 0 { try String(getpid()).write(to: paths.pidFile(connection), atomically: true, encoding: .utf8) }
    }

    func serve(_ connection: Connection, respond: @escaping ControlServer.Respond) throws {
        try ConnectionStore(url: paths.config).save(connection)
        try servers.start(at: paths.socket(connection), respond: respond)
    }

    func signInReturns(_ token: String) throws {
        try token.write(to: root.appending(path: "authorize-token"), atomically: true, encoding: .utf8)
    }

    func signInWillHang() throws {
        try signInReturns(#"{"access_token":"late","refresh_token":"1//late-refresh"}"#)
        FileManager.default.createFile(atPath: root.appending(path: "authorize-hang").path, contents: Data())
    }

    func waitForSignInToStop(_ pid: pid_t) async throws {
        try await waitUntil(timeout: .seconds(5)) { kill(pid, 0) != 0 }
    }

    func signInHangs() async throws -> pid_t {
        let pidFile = root.appending(path: "authorize-pid")
        try await waitUntil { FileManager.default.fileExists(atPath: pidFile.path) && !((try? String(contentsOf: pidFile, encoding: .utf8)) ?? "").isEmpty }
        return try #require(pid_t(String(contentsOf: pidFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)))
    }

    func signInFails(_ output: String) throws {
        try output.write(to: root.appending(path: "authorize-error"), atomically: true, encoding: .utf8)
    }

    var signInEnvironment: String { (try? String(contentsOf: root.appending(path: "authorize-env"), encoding: .utf8)) ?? "" }

    func queue(_ items: String...) throws { try queue(contentsOf: items) }

    private func queue(contentsOf items: [String]) throws {
        try Data(#"{"queue":[\#(items.joined(separator: ","))]}"#.utf8).write(to: root.appending(path: "queue.json"))
    }

    func saveEncryptedConnection() throws -> Connection {
        let connection = Connection.s3 { $0.encrypted = true }
        try repository.save(connection, credentials: Credentials(
            accessKey: "saved-access", secretKey: "saved-secret", sessionToken: "saved-token", encryptionPassword: "saved-password",
        ))
        return connection
    }

    func remove() {
        servers.stop()
        drives.remove()
    }
}

private final class ControlServers: Sendable {
    private let servers = Mutex<[ControlServer]>([])

    func start(at socket: URL, respond: @escaping ControlServer.Respond) throws {
        let server = try ControlServer(at: socket, respond: respond)
        servers.withLock { $0.append(server) }
    }

    func stop() { servers.withLock { $0.forEach { $0.stop() } } }
}

final class Overlap: Sendable {
    private let state = Mutex((inFlight: 0, peak: 0))

    func hold() {
        state.withLock {
            $0.inFlight += 1
            $0.peak = max($0.peak, $0.inFlight)
        }
    }

    func release() { state.withLock { $0.inFlight -= 1 } }

    var peak: Int { state.withLock { $0.peak } }
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
    var rcloneConfigDestination: RcloneConfigDestination?

    init(paths: AppPaths) { self.paths = paths }

    func setOpensAtLogin(_ enabled: Bool) throws {
        if let loginError { throw loginError }
        opensAtLogin = enabled
    }

    func mountLocation(_ connection: Connection) -> URL { paths.mount(connection) }
    func openDrive(_ connection: Connection) { openedDrives.append(connection.id) }
    func openLog(_: Connection) {}
    func copyShareLinks(_ links: [URL]) { copiedLinks = links }
    func chooseRcloneConfigDestination(for _: Connection) -> RcloneConfigDestination? { rcloneConfigDestination }
    func notify(title: String, body: String, fallbackToAlert: Bool) {
        notifications.append(Notification(title: title, body: body, fallbackToAlert: fallbackToAlert))
    }
}

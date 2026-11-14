import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class AppViewModel {
    public enum Activity { case idle, connected, uploading, downloading }
    public enum Indicator { case working, attention, connected, idle }
    public enum SidebarItem: Hashable, Sendable { case traffic, drive(UUID) }

    public private(set) var connections: [Connection] = []
    public var selection: SidebarItem?
    public var searchQuery = ""
    public internal(set) var isSearching = false
    public internal(set) var searchFocusRequest = 0
    public static let speedWindow: TimeInterval = 60
    public internal(set) var statuses: [UUID: MountStatus] = [:]
    public internal(set) var speeds: [UUID: [SpeedSample]] = [:]
    public internal(set) var errors: [UUID: String] = [:]
    public internal(set) var busy: Set<UUID> = [] {
        didSet { if refreshing { refreshRequested = true } }
    }

    var pendingTrust: [UUID: (challenge: ServerTrustChallenge, opensFinder: Bool)] = [:]
    var signInRequired: Set<UUID> = []
    var signIns: [UUID: GoogleSignInRun] = [:]
    public var alert: String?
    public var disconnectFailure: Connection?
    public var uploadsBlockingDisconnect: Connection?
    public var editor: ConnectionDraft?
    public var deleting: Connection?
    public var uploadCleanup: UploadCleanup?
    public private(set) var ready = false
    public private(set) var opensAtLogin: Bool
    var networkAvailable = true
    var sleeping = false

    let drives: any DriveGateway
    private let deleteConnection: DeleteConnectionUseCase
    private let setAutomaticConnect: SetAutomaticConnectUseCase
    let connectDrive: ConnectDriveUseCase
    let signInAgain: SignInAgainUseCase
    let shareFiles: ShareFilesUseCase
    let duplicateFiles: DuplicateFilesUseCase
    private let exportConfig: ExportRcloneConfigUseCase
    let quit: QuitUseCase
    let desktop: any DesktopServices
    var refreshing = false
    var refreshRequested = false
    var checkingQuit = false
    var notifiedFailures: Set<UUID> = []
    var waitingToDisconnect: Set<UUID> = []

    public init(
        initialConnections: Result<[Connection], any Error>,
        drives: any DriveGateway,
        deleteConnection: DeleteConnectionUseCase,
        setAutomaticConnect: SetAutomaticConnectUseCase,
        connectDrive: ConnectDriveUseCase,
        signInAgain: SignInAgainUseCase,
        shareFiles: ShareFilesUseCase,
        duplicateFiles: DuplicateFilesUseCase,
        exportConfig: ExportRcloneConfigUseCase,
        quit: QuitUseCase,
        desktop: any DesktopServices,
    ) {
        self.drives = drives
        self.deleteConnection = deleteConnection
        self.setAutomaticConnect = setAutomaticConnect
        self.connectDrive = connectDrive
        self.signInAgain = signInAgain
        self.shareFiles = shareFiles
        self.duplicateFiles = duplicateFiles
        self.exportConfig = exportConfig
        self.quit = quit
        self.desktop = desktop
        opensAtLogin = desktop.opensAtLogin
        switch initialConnections {
        case let .success(connections):
            self.connections = connections
            selection = connections.first.map { .drive($0.id) }
            ready = true
        case let .failure(error):
            alert = error.localizedDescription
        }
    }

    public var unsavedTraffic: [UUID: Traffic] { statuses.mapValues(\.unsavedTraffic) }

    public var selected: Connection? {
        guard case let .drive(id) = selection else { return nil }
        return connections.first { $0.id == id }
    }

    public var isShowingAlert: Bool {
        get { alert != nil }
        set { if !newValue { alert = nil } }
    }

    public var isConfirmingDelete: Bool {
        get { deleting != nil }
        set { if !newValue { deleting = nil } }
    }

    public var isShowingDisconnectFailure: Bool {
        get { disconnectFailure != nil }
        set { if !newValue { disconnectFailure = nil } }
    }

    public var isShowingUploadsBlockingDisconnect: Bool {
        get { uploadsBlockingDisconnect != nil }
        set { if !newValue { uploadsBlockingDisconnect = nil } }
    }

    public func edit(_ connection: Connection) {
        editor = ConnectionDraft(connection: connection)
    }

    public func duplicate(_ connection: Connection) {
        editor = ConnectionDraft(duplicating: connection)
    }

    func connectionSaved(_ connection: Connection, connections: [Connection]) {
        self.connections = connections
        selection = .drive(connection.id)
        statuses[connection.id] = MountStatus()
        clearProblem(connection)
    }

    public func setConnectsAutomatically(_ connectsAutomatically: Bool, for connection: Connection) {
        do {
            connections = try setAutomaticConnect.execute(connection, connectsAutomatically: connectsAutomatically)
        } catch { alert = error.localizedDescription }
    }

    public func delete(_ connection: Connection) async {
        busy.insert(connection.id)
        defer { busy.remove(connection.id) }
        do {
            connections = try await deleteConnection.execute(connection)
            statuses[connection.id] = nil
            clearProblem(connection)
            if selection != .traffic { selection = connections.first.map { .drive($0.id) } }
        } catch { alert = error.localizedDescription }
    }

    public func exportRcloneConfig(_ connection: Connection) async {
        guard let destination = desktop.chooseRcloneConfigDestination(for: connection) else { return }
        do {
            try await exportConfig.execute(connection, to: destination.url, includesSecrets: destination.includesSecrets)
        } catch { alert = error.localizedDescription }
    }

    public func refreshFiles(_ connection: Connection) async {
        do {
            try await drives.refresh(connection)
        } catch { errors[connection.id] = error.localizedDescription }
    }

    public func checkAgain(_ connection: Connection) async {
        clearProblem(connection)
        await refresh()
    }

    public func setOpensAtLogin(_ enabled: Bool) {
        do {
            try desktop.setOpensAtLogin(enabled)
        } catch { alert = error.localizedDescription }
        syncOpensAtLogin()
    }

    public func syncOpensAtLogin() {
        let enabled = desktop.opensAtLogin
        if opensAtLogin != enabled { opensAtLogin = enabled }
    }
}

public extension AppViewModel {
    func isOffline(_ connection: Connection) -> Bool {
        isActive(connection) && !networkAvailable
    }

    func mountLocation(_ connection: Connection) -> URL { desktop.mountLocation(connection) }

    func openDrive(_ connection: Connection) { desktop.openDrive(connection) }
    func openLog(_ connection: Connection) { desktop.openLog(connection) }
}

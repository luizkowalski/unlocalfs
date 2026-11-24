import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class AppViewModel {
    public enum Activity { case idle, connected, uploading, downloading }
    public enum Indicator { case working, attention, connected, idle }
    public enum SidebarItem: Hashable, Sendable { case traffic, drive(UUID) }
    public enum DriveToggle: Sendable { case connect, disconnect, reconnect }

    public private(set) var connections: [Connection] = []
    public var selection: SidebarItem?
    public var searchQuery = ""
    public internal(set) var isSearching = false
    public internal(set) var searchFocusRequest = 0
    public static let speedWindow: TimeInterval = 60
    var statuses: [UUID: MountStatus] = [:]
    public internal(set) var speeds: [UUID: [SpeedSample]] = [:]
    var errors: [UUID: String] = [:]
    var busy: Set<UUID> = [] {
        didSet { if refreshing { refreshRequested = true } }
    }

    var pendingTrust: [UUID: (challenge: ServerTrustChallenge, opensFinder: Bool)] = [:]
    var signInRequired: Set<UUID> = []
    var signIns: [UUID: GoogleSignInRun] = [:]
    public var alert: AppAlert?
    public var disconnectFailure: Connection?
    public var uploadsBlockingDisconnect: Connection?
    public var editor: ConnectionDraft?
    public var deleting: Connection?
    public var uploadCleanup: UploadCleanup?
    public private(set) var ready = false
    public private(set) var opensAtLogin: Bool
    var networkAvailable = true
    var sleeping = false

    private let repository: any ConnectionRepository
    let drives: any DriveGateway
    private let deleteConnection: DeleteConnectionUseCase
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
    var disconnectingAll = false
    @ObservationIgnored var announcedFinderSnapshot: FinderSnapshot?
    @ObservationIgnored var statusCheckedAt: [UUID: Date] = [:]

    public init(
        initialConnections: Result<[Connection], any Error>,
        repository: any ConnectionRepository,
        drives: any DriveGateway,
        deleteConnection: DeleteConnectionUseCase,
        connectDrive: ConnectDriveUseCase,
        signInAgain: SignInAgainUseCase,
        shareFiles: ShareFilesUseCase,
        duplicateFiles: DuplicateFilesUseCase,
        exportConfig: ExportRcloneConfigUseCase,
        quit: QuitUseCase,
        desktop: any DesktopServices,
    ) {
        self.repository = repository
        self.drives = drives
        self.deleteConnection = deleteConnection
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
            alert = AppAlert(String(localized: .drivesNotLoaded), error)
        }
    }

    public var unsavedTraffic: [UUID: Traffic] { statuses.mapValues(\.unsavedTraffic) }

    public var selected: Connection? {
        guard case let .drive(id) = selection else { return nil }
        return connections.first { $0.id == id }
    }

    public func edit(_ connection: Connection) {
        guard canStartEditing else { return }
        editor = ConnectionDraft(connection: connection)
    }

    public func duplicate(_ connection: Connection) {
        guard canStartEditing else { return }
        editor = ConnectionDraft(duplicating: connection)
    }

    func connectionSaved(_ connection: Connection, connections: [Connection]) {
        self.connections = connections
        selection = .drive(connection.id)
        statuses[connection.id] = MountStatus()
        clearProblem(connection)
    }

    public func setConnectsAutomatically(_ connectsAutomatically: Bool, for connection: Connection) {
        var connection = connection
        connection.connectsAutomatically = connectsAutomatically
        do {
            try repository.save(connection)
            connections = try repository.all()
        } catch { alert = AppAlert(String(localized: .driveNotSaved(connection.name)), error) }
    }

    public func delete(_ connection: Connection) async {
        await operate(on: connection, when: canEdit(connection)) {
            do {
                connections = try await deleteConnection.execute(connection)
                await forget(connection)
                if selection != .traffic { selection = connections.first.map { .drive($0.id) } }
            } catch { alert = AppAlert(String(localized: .driveNotDeleted(connection.name)), error) }
        }
    }

    private func forget(_ connection: Connection) async {
        let id = connection.id
        if let pending = pendingTrust.removeValue(forKey: id) { await drives.cancelServerTrust(pending.challenge) }
        signIns.removeValue(forKey: id)?.cancel()
        statuses[id] = nil
        speeds[id] = nil
        errors[id] = nil
        signInRequired.remove(id)
        notifiedFailures.remove(id)
        waitingToDisconnect.remove(id)
        statusCheckedAt[id] = nil
    }

    public func exportRcloneConfig(_ connection: Connection) async {
        guard let destination = desktop.chooseRcloneConfigDestination(for: connection) else { return }
        do {
            try await exportConfig.execute(connection, to: destination.url, includesSecrets: destination.includesSecrets)
        } catch { alert = AppAlert(String(localized: .configNotExported(connection.name)), error) }
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
        } catch { alert = AppAlert(String(localized: .openAtLoginNotChanged), error) }
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

    func mountLocation(_ connection: Connection) -> URL { drives.mountLocation(connection) }

    func openDrive(_ connection: Connection) { desktop.openDrive(connection) }
    func openLog(_ connection: Connection) { desktop.openLog(connection) }
}

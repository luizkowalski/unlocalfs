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
    public private(set) var statuses: [UUID: MountStatus] = [:]
    public private(set) var speeds: [UUID: [SpeedSample]] = [:]
    public internal(set) var errors: [UUID: String] = [:]
    public internal(set) var busy: Set<UUID> = [] {
        didSet { if refreshing { refreshRequested = true } }
    }

    private var pendingTrust: [UUID: (challenge: ServerTrustChallenge, opensFinder: Bool)] = [:]
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
    private var networkAvailable = true
    private var sleeping = false

    let drives: any DriveGateway
    private let deleteConnection: DeleteConnectionUseCase
    private let setAutomaticConnect: SetAutomaticConnectUseCase
    private let connectDrive: ConnectDriveUseCase
    let signInAgain: SignInAgainUseCase
    let shareFiles: ShareFilesUseCase
    let duplicateFiles: DuplicateFilesUseCase
    private let exportConfig: ExportRcloneConfigUseCase
    private let quit: QuitUseCase
    let desktop: any DesktopServices
    private var refreshing = false
    private var refreshRequested = false
    var checkingQuit = false
    private var notifiedFailures: Set<UUID> = []
    private var waitingToDisconnect: Set<UUID> = []

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

    public func run() async {
        await refresh()
        await connectAutomatically()
        while !Task.isCancelled {
            await refresh()
            do {
                try await Task.sleep(for: .seconds(3))
            } catch { return }
        }
    }

    public func serverTrust(for connection: Connection) -> ServerTrustChallenge? {
        pendingTrust[connection.id]?.challenge
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

    public func activate(_ connection: Connection) async {
        if canOpen(connection) || !isActive(connection) || needsReconnect(connection) {
            await connect(connection, opensFinder: true)
        }
    }

    public func toggle(_ connection: Connection, opensFinder: Bool = false) async {
        if canDisconnect(connection) {
            await disconnect(connection)
        } else {
            await connect(connection, opensFinder: opensFinder)
        }
    }

    private func connect(_ connection: Connection, opensFinder: Bool) async {
        guard !checkingQuit, canToggle(connection) else { return }
        closeSearch()
        busy.insert(connection.id)
        clearProblem(connection)
        defer { busy.remove(connection.id) }
        if let pending = pendingTrust.removeValue(forKey: connection.id) { await drives.cancelServerTrust(pending.challenge) }
        do {
            let outcome = try await connectDrive.execute(connection)
            if opensFinder {
                switch outcome {
                case .connected: openDrive(connection)
                case .ejected: break
                }
            }
        } catch let challenge as ServerTrustChallenge {
            pendingTrust[connection.id] = (challenge, opensFinder)
            errors[connection.id] = challenge.localizedDescription
            selection = .drive(connection.id)
        } catch {
            if error is GoogleSignInRequired { signInRequired.insert(connection.id) }
            errors[connection.id] = error.localizedDescription
        }
        await update(drives.status(connection), for: connection)
    }

    public func disconnect(_ connection: Connection) async {
        guard !checkingQuit, canDisconnect(connection) else { return }
        busy.insert(connection.id)
        clearProblem(connection)
        if disconnectFailure?.id == connection.id { disconnectFailure = nil }
        waitingToDisconnect.remove(connection.id)
        defer { busy.remove(connection.id) }
        do {
            try await drives.unmount(connection)
        } catch is UploadsPendingError {
            uploadsBlockingDisconnect = connection
            waitingToDisconnect.insert(connection.id)
            selection = .drive(connection.id)
        } catch is DriveEjectError {
            disconnectFailure = connection
        } catch {
            errors[connection.id] = error.localizedDescription
        }
        await update(drives.status(connection), for: connection)
    }

    public func trustServer(_ connection: Connection) async {
        guard let pending = pendingTrust.removeValue(forKey: connection.id) else { return }
        busy.insert(connection.id)
        do {
            try await drives.trustServer(pending.challenge)
            busy.remove(connection.id)
            await connect(connection, opensFinder: pending.opensFinder)
        } catch {
            busy.remove(connection.id)
            errors[connection.id] = error.localizedDescription
        }
    }

    public func cancelServerTrust(_ connection: Connection) async {
        guard let pending = pendingTrust.removeValue(forKey: connection.id) else { return }
        await drives.cancelServerTrust(pending.challenge)
    }

    public func disconnectAll() async {
        for connection in connections where canDisconnect(connection) {
            await disconnect(connection)
            if isActive(connection) {
                selection = .drive(connection.id)
                return
            }
        }
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

    private func connectAutomatically() async {
        await withTaskGroup(of: Void.self) { group in
            for connection in connections {
                if let status = statuses[connection.id], connection.shouldConnectAutomatically(status: status) {
                    group.addTask { await self.connect(connection, opensFinder: false) }
                }
            }
        }
    }

    public func refresh() async {
        guard !sleeping else { return }
        if refreshing {
            refreshRequested = true
            return
        }
        refreshing = true
        defer { refreshing = false }
        repeat {
            refreshRequested = false
            let checked = connections.filter { !busy.contains($0.id) }
            await withTaskGroup(of: (Connection, MountStatus).self) { group in
                for connection in checked {
                    group.addTask { [drives] in await (connection, drives.status(connection)) }
                }
                for await (connection, status) in group {
                    guard !sleeping, !refreshRequested, !busy.contains(connection.id) else { continue }
                    update(status, for: connection)
                }
            }
        } while refreshRequested && !sleeping
    }

    public func willSleep() { sleeping = true }

    public func didWake() async {
        sleeping = false
        await refresh()
    }

    public func networkChanged(available: Bool) async {
        networkAvailable = available
        await refresh()
    }

    public func quitDecision() async -> QuitUseCase.Decision {
        checkingQuit = true
        return await quit.execute(connections: connections, operationInProgress: !busy.isEmpty)
    }

    public func cancelQuit() { checkingQuit = false }

    public func stopSignInsForQuit() async { await drives.stopSignIns() }

    public func disconnectForQuit() async -> (connection: Connection, error: any Error)? {
        checkingQuit = true
        let active = Set(connections.filter(isActive).map(\.id))
        busy.formUnion(active)
        let failure = await quit.disconnectAll(connections: connections)
        busy.subtract(active)
        await refresh()
        return failure
    }
}

public extension AppViewModel {
    func isOffline(_ connection: Connection) -> Bool {
        isActive(connection) && !networkAvailable
    }

    func mountLocation(_ connection: Connection) -> URL { desktop.mountLocation(connection) }

    internal func recordSpeed(_ sample: SpeedSample, for id: UUID) {
        var samples = speeds[id, default: []]
        samples.removeAll { !(0 ..< Self.speedWindow).contains(sample.date.timeIntervalSince($0.date)) }
        if let last = samples.last, floor(last.date.timeIntervalSinceReferenceDate) == floor(sample.date.timeIntervalSinceReferenceDate) {
            if last.upload == sample.upload, last.download == sample.download { return }
            samples.removeLast()
        }
        samples.append(sample)
        speeds[id] = samples
    }

    func openDrive(_ connection: Connection) { desktop.openDrive(connection) }
    func openLog(_ connection: Connection) { desktop.openLog(connection) }
}

extension AppViewModel {
    private func clearProblem(_ connection: Connection) {
        errors[connection.id] = nil
        signInRequired.remove(connection.id)
    }

    func update(_ status: MountStatus, for connection: Connection) {
        if status.failedUploads > 0, notifiedFailures.insert(connection.id).inserted {
            let body = status.uploadError.map { String(localized: .uploadsFailedReason($0)) } ?? String(localized: .uploadsFailedBody)
            desktop.notify(title: String(localized: .uploadsFailed(connection.name)), body: body, fallbackToAlert: false)
        }
        if status.isServing, status.pendingUploads == 0, status.failedUploads == 0 {
            notifiedFailures.remove(connection.id)
            if waitingToDisconnect.remove(connection.id) != nil {
                desktop.notify(title: String(localized: .finishedUploading(connection.name)), body: String(localized: .canDisconnectNow), fallbackToAlert: false)
            }
        }
        if statuses[connection.id] != status { statuses[connection.id] = status }
        if status.isServing {
            recordSpeed(SpeedSample(status, at: .now), for: connection.id)
        } else if !status.isRunning, speeds[connection.id] != nil {
            speeds[connection.id] = nil
        }
    }
}

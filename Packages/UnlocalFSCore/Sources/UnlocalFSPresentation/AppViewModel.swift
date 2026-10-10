import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class AppViewModel {
    public enum Activity { case idle, connected, syncing }
    public enum Indicator { case working, attention, connected, idle }

    public private(set) var connections: [Connection] = []
    public var selection: UUID?
    public private(set) var statuses: [UUID: MountStatus] = [:]
    public private(set) var errors: [UUID: String] = [:]
    public private(set) var busy: Set<UUID> = []
    public private(set) var serverTrust: [UUID: ServerTrustChallenge] = [:]
    private var trustOpensFinder: [UUID: Bool] = [:]
    public var alert: String?
    public var disconnectFailure: Connection?
    public var uploadsBlockingDisconnect: Connection?
    public var editor: ConnectionDraft?
    public var deleting: Connection?
    public var isConfirmingDisconnectAll = false
    public private(set) var ready = false
    public private(set) var opensAtLogin: Bool
    private var networkAvailable = true
    private var sleeping = false

    private let drives: any DriveGateway
    private let deleteConnection: DeleteConnectionUseCase
    private let connectDrive: ConnectDriveUseCase
    private let shareFiles: ShareFilesUseCase
    private let exportConfig: ExportRcloneConfigUseCase
    private let quit: QuitUseCase
    private let desktop: any DesktopServices
    private var refreshing = false
    private var refreshRequested = false
    private var checkingQuit = false
    private var notifiedFailures: Set<UUID> = []
    private var waitingToDisconnect: Set<UUID> = []

    public init(
        initialConnections: Result<[Connection], any Error>,
        drives: any DriveGateway,
        deleteConnection: DeleteConnectionUseCase,
        connectDrive: ConnectDriveUseCase,
        shareFiles: ShareFilesUseCase,
        exportConfig: ExportRcloneConfigUseCase,
        quit: QuitUseCase,
        desktop: any DesktopServices
    ) {
        self.drives = drives
        self.deleteConnection = deleteConnection
        self.connectDrive = connectDrive
        self.shareFiles = shareFiles
        self.exportConfig = exportConfig
        self.quit = quit
        self.desktop = desktop
        opensAtLogin = desktop.opensAtLogin
        switch initialConnections {
        case .success(let connections):
            self.connections = connections
            selection = connections.first?.id
            ready = true
        case .failure(let error):
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

    public var selected: Connection? { connections.first { $0.id == selection } }

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
        selection = connection.id
        statuses[connection.id] = MountStatus()
        errors[connection.id] = nil
    }

    public func delete(_ connection: Connection) async {
        busy.insert(connection.id)
        defer { busy.remove(connection.id) }
        do {
            connections = try await deleteConnection.execute(connection)
            statuses[connection.id] = nil
            errors[connection.id] = nil
            selection = connections.first?.id
        } catch { alert = error.localizedDescription }
    }

    public func activate(_ connection: Connection) async {
        guard !checkingQuit, canToggle(connection) else { return }
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
        busy.insert(connection.id)
        errors[connection.id] = nil
        defer { busy.remove(connection.id) }
        if let pending = serverTrust.removeValue(forKey: connection.id) { await drives.cancelServerTrust(pending) }
        do {
            let outcome = try await connectDrive.execute(connection)
            if opensFinder {
                switch outcome {
                case .connected, .reconnected: openDrive(connection)
                case .ejected: break
                }
            }
        } catch let challenge as ServerTrustChallenge {
            serverTrust[connection.id] = challenge
            trustOpensFinder[connection.id] = opensFinder
            errors[connection.id] = challenge.localizedDescription
            selection = connection.id
        } catch {
            errors[connection.id] = error.localizedDescription
        }
        update(await drives.status(connection), for: connection)
    }

    public func disconnect(_ connection: Connection) async {
        guard !checkingQuit, canDisconnect(connection) else { return }
        busy.insert(connection.id)
        errors[connection.id] = nil
        if disconnectFailure?.id == connection.id { disconnectFailure = nil }
        waitingToDisconnect.remove(connection.id)
        defer { busy.remove(connection.id) }
        do {
            try await drives.unmount(connection)
        } catch is UploadsPendingError {
            uploadsBlockingDisconnect = connection
            waitingToDisconnect.insert(connection.id)
            selection = connection.id
        } catch is DriveEjectError {
            disconnectFailure = connection
        } catch {
            errors[connection.id] = error.localizedDescription
        }
        update(await drives.status(connection), for: connection)
    }

    public func trustServer(_ connection: Connection) async {
        guard let challenge = serverTrust.removeValue(forKey: connection.id) else { return }
        let opensFinder = trustOpensFinder.removeValue(forKey: connection.id) ?? false
        busy.insert(connection.id)
        do {
            try await drives.trustServer(challenge)
            busy.remove(connection.id)
            await connect(connection, opensFinder: opensFinder)
        } catch {
            busy.remove(connection.id)
            errors[connection.id] = error.localizedDescription
        }
    }

    public func cancelServerTrust(_ connection: Connection) async {
        guard let challenge = serverTrust.removeValue(forKey: connection.id) else { return }
        trustOpensFinder[connection.id] = nil
        await drives.cancelServerTrust(challenge)
    }

    public func requestDisconnectAll() {
        isConfirmingDisconnectAll = connections.contains(where: canDisconnect)
    }

    public func disconnectAll() async {
        for connection in connections where canDisconnect(connection) {
            await disconnect(connection)
            if isActive(connection) {
                selection = connection.id
                return
            }
        }
    }

    public func copyShareLinks(for files: [URL], expiry: ShareLinkExpiry) async {
        do {
            let links = try await shareFiles.execute(files, expiry: expiry)
            desktop.copyShareLinks(links)
            desktop.notify(
                title: String(localized: .linksCopied(links.count)),
                body: String(localized: .anyoneCanDownload(expiry.title)), fallbackToAlert: false
            )
        } catch let error as ShareFileError {
            desktop.notify(title: String(localized: .couldNotCopyLink(error.file.lastPathComponent)), body: error.localizedDescription, fallbackToAlert: true)
        } catch {
            desktop.notify(title: String(localized: .couldNotCopyShareLinks), body: error.localizedDescription, fallbackToAlert: true)
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
        errors[connection.id] = nil
        await refresh()
    }

    public func setOpensAtLogin(_ enabled: Bool) {
        do {
            try desktop.setOpensAtLogin(enabled)
        } catch { alert = error.localizedDescription }
        syncOpensAtLogin()
    }

    private func syncOpensAtLogin() {
        let enabled = desktop.opensAtLogin
        if opensAtLogin != enabled { opensAtLogin = enabled }
    }

    private func connectAutomatically() async {
        for connection in connections {
            if let status = statuses[connection.id], connection.shouldConnectAutomatically(status: status) {
                await connect(connection, opensFinder: false)
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
            syncOpensAtLogin()
            for connection in connections where !busy.contains(connection.id) && !sleeping {
                let status = await drives.status(connection)
                if !sleeping, !busy.contains(connection.id) { update(status, for: connection) }
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

    public func canQuit() async -> Bool {
        checkingQuit = true
        defer { checkingQuit = false }
        do {
            try await quit.execute(connections: connections, operationInProgress: !busy.isEmpty)
            return true
        } catch {
            alert = error.localizedDescription
            return false
        }
    }
}

extension AppViewModel {
    public func isOffline(_ connection: Connection) -> Bool {
        isActive(connection) && !networkAvailable
    }

    public func mountLocation(_ connection: Connection) -> URL { desktop.mountLocation(connection) }

    public func openDrive(_ connection: Connection) { desktop.openDrive(connection) }
    public func openLog(_ connection: Connection) { desktop.openLog(connection) }
}

private extension AppViewModel {
    func update(_ status: MountStatus, for connection: Connection) {
        if status.failedUploads > 0, notifiedFailures.insert(connection.id).inserted {
            notify(title: String(localized: .uploadsFailed(connection.name)), body: String(localized: .uploadsFailedBody))
        }
        if status.isRunning, !status.needsReconnect, status.pendingUploads == 0, status.failedUploads == 0 {
            notifiedFailures.remove(connection.id)
            if waitingToDisconnect.remove(connection.id) != nil {
                notify(title: String(localized: .finishedUploading(connection.name)), body: String(localized: .canDisconnectNow))
            }
        }
        if statuses[connection.id] != status { statuses[connection.id] = status }
    }

    func notify(title: String, body: String) {
        desktop.notify(title: title, body: body, fallbackToAlert: false)
    }
}

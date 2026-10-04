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
    public var alert: String?
    public var editor: ConnectionDraft?
    public var deleting: Connection?
    public private(set) var ready = false
    public private(set) var opensAtLogin: Bool
    private var networkAvailable = true
    private var sleeping = false

    private let drives: any DriveGateway
    private let deleteConnection: DeleteConnectionUseCase
    private let toggleDrive: ToggleDriveUseCase
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
        toggleDrive: ToggleDriveUseCase,
        shareFiles: ShareFilesUseCase,
        exportConfig: ExportRcloneConfigUseCase,
        quit: QuitUseCase,
        desktop: any DesktopServices
    ) {
        self.drives = drives
        self.deleteConnection = deleteConnection
        self.toggleDrive = toggleDrive
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
            await toggle(connection, opensFinder: true, allowsDisconnect: false)
        }
    }

    public func toggle(_ connection: Connection, opensFinder: Bool = false, allowsDisconnect: Bool = true) async {
        guard !checkingQuit, canToggle(connection) else { return }
        busy.insert(connection.id)
        errors[connection.id] = nil
        if allowsDisconnect { waitingToDisconnect.remove(connection.id) }
        defer { busy.remove(connection.id) }
        do {
            let outcome = try await toggleDrive.execute(connection, allowsDisconnect: allowsDisconnect)
            if opensFinder {
                switch outcome {
                case .connected, .reconnected: openDrive(connection)
                case .disconnected: break
                }
            }
        } catch is UploadsPendingError {
            waitingToDisconnect.insert(connection.id)
        } catch {
            errors[connection.id] = error.localizedDescription
        }
        update(await drives.status(connection), for: connection)
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
                await toggle(connection)
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
    public var activity: Activity {
        if statuses.values.contains(where: { $0.pendingUploads > 0 }) { return .syncing }
        return statuses.values.contains(where: \.isMounted) ? .connected : .idle
    }

    public func isActive(_ connection: Connection) -> Bool {
        statuses[connection.id]?.isActive == true
    }

    public func isOffline(_ connection: Connection) -> Bool {
        isActive(connection) && !networkAvailable
    }

    public func servingStatus(_ connection: Connection) -> MountStatus? {
        guard let status = statuses[connection.id], status.isRunning, !status.needsReconnect else { return nil }
        return status
    }

    public func problem(_ connection: Connection) -> String? {
        errors[connection.id] ?? statuses[connection.id]?.controlError
    }

    public func uploadNotice(_ connection: Connection) -> String? {
        guard let status = statuses[connection.id], status.pendingUploads > 0, status.failedUploads == 0 else { return nil }
        return status.isMounted
            ? String(localized: .uploadsPendingKeepDriveConnected)
            : String(localized: .uploadsPendingKeepAppRunning)
    }

    public func canToggle(_ connection: Connection) -> Bool {
        !busy.contains(connection.id) && statuses[connection.id] != nil && editor?.id != connection.id
    }

    public func canOpen(_ connection: Connection) -> Bool {
        statuses[connection.id]?.isMounted == true && !needsReconnect(connection)
    }

    public func canEdit(_ connection: Connection) -> Bool {
        canToggle(connection) && !isActive(connection)
    }

    public func indicator(_ connection: Connection) -> Indicator {
        switch condition(connection) {
        case .working: .working
        case .needsReconnect, .needsAttention, .offline, .uploadFailed: .attention
        default: statuses[connection.id]?.isMounted == true ? .connected : .idle
        }
    }

    public func statusText(_ connection: Connection) -> String {
        switch condition(connection) {
        case .working: String(localized: .working)
        case .needsReconnect: String(localized: .needsReconnect)
        case .needsAttention: String(localized: .needsAttention)
        case .checking: String(localized: .checking)
        case .offline: String(localized: .networkUnavailable)
        case .uploadFailed: String(localized: .uploadNeedsAttention)
        case .uploading(let count): String(localized: .uploadsPending(count))
        case .connected: String(localized: .connected)
        case .ejected: String(localized: .ejected)
        case .disconnected: String(localized: .disconnected)
        }
    }

    public func needsReconnect(_ connection: Connection) -> Bool {
        statuses[connection.id]?.needsReconnect == true
    }

    public func toggleTitle(_ connection: Connection) -> String {
        if needsReconnect(connection) { return String(localized: .reconnect) }
        return isActive(connection) ? String(localized: .disconnect) : String(localized: .connect)
    }

    public func mountLocation(_ connection: Connection) -> URL { desktop.mountLocation(connection) }

    public func openDrive(_ connection: Connection) { desktop.openDrive(connection) }
    public func openLog(_ connection: Connection) { desktop.openLog(connection) }
}

private extension AppViewModel {
    enum Condition {
        case working, needsReconnect, needsAttention, checking, offline, uploadFailed, uploading(Int), connected, ejected, disconnected
    }

    func condition(_ connection: Connection) -> Condition {
        if busy.contains(connection.id) { return .working }
        if needsReconnect(connection) { return .needsReconnect }
        if errors[connection.id] != nil { return .needsAttention }
        guard let status = statuses[connection.id] else { return .checking }
        if status.isActive && !networkAvailable { return .offline }
        if status.failedUploads > 0 { return .uploadFailed }
        if status.pendingUploads > 0 { return .uploading(status.pendingUploads) }
        if status.isMounted { return .connected }
        if status.isRunning { return .ejected }
        return .disconnected
    }

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

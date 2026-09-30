import AppKit
import Observation
import OSLog
import ServiceManagement
import UnlocalFSCore
import UserNotifications

@MainActor @Observable final class AppModel {
    enum Activity { case idle, connected, syncing }

    struct Draft: Identifiable {
        var connection: Connection
        var credentialsSource: UUID
        var id: UUID { connection.id }
        var isDuplicate: Bool { credentialsSource != connection.id }
    }

    var connections: [Connection] = []
    var selection: UUID?
    var statuses: [UUID: MountStatus] = [:]
    var errors: [UUID: String] = [:]
    var busy: Set<UUID> = []
    var alert: String?
    var editor: Draft?
    var deleting: Connection?
    private(set) var ready = false
    private(set) var opensAtLogin = SMAppService.mainApp.status == .enabled
    private(set) var networkAvailable = true
    private var sleeping = false

    let paths = AppPaths.standard
    let service: MountService
    private let keychain = Keychain()
    private let store: ConnectionStore
    private var refreshing = false
    private var refreshRequested = false
    private var checkingQuit = false
    private var notifiedFailures: Set<UUID> = []
    private var waitingToDisconnect: Set<UUID> = []

    init() {
        let contents = Bundle.main.bundleURL.appending(path: "Contents")
        service = MountService(
            executable: contents.appending(path: "Helpers/rclone"),
            helperDirectory: contents.appending(path: "Resources/libexec"),
            paths: paths
        )
        store = ConnectionStore(url: paths.config)
        do {
            try paths.prepare()
            connections = try store.all()
            selection = connections.first?.id
            ready = true
        } catch { alert = error.localizedDescription }
        Task {
            await refresh()
            await connectAutomatically()
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    var selected: Connection? { connections.first { $0.id == selection } }

    var isShowingAlert: Bool {
        get { alert != nil }
        set { if !newValue { alert = nil } }
    }

    var isConfirmingDelete: Bool {
        get { deleting != nil }
        set { if !newValue { deleting = nil } }
    }

    func credentials(for id: UUID) throws -> Credentials {
        try keychain.read(id) ?? Credentials()
    }

    func edit(_ connection: Connection) {
        editor = Draft(connection: connection, credentialsSource: connection.id)
    }

    func duplicate(_ connection: Connection) {
        var copy = connection
        copy.id = UUID()
        copy.name = "\(connection.name) copy"
        editor = Draft(connection: copy, credentialsSource: connection.id)
    }

    func save(_ connection: Connection, credentials: Credentials) async throws {
        try AppError.throwing(credentials.validate(for: connection))
        let credentials = try await service.prepareCredentials(credentials)
        let previous = connections.first { $0.id == connection.id }
        try store.save(connection)
        do {
            try keychain.save(credentials, for: connection.id)
        } catch {
            if let previous {
                try store.save(previous)
            } else {
                try store.delete(connection.id)
            }
            throw error
        }
        connections = try store.all()
        selection = connection.id
        statuses[connection.id] = MountStatus()
        errors[connection.id] = nil
    }

    func delete(_ connection: Connection) async {
        busy.insert(connection.id)
        defer { busy.remove(connection.id) }
        do {
            guard await !service.status(connection).isActive else { throw AppError("Disconnect this drive before deleting it.") }
            try keychain.delete(connection.id)
            try store.delete(connection.id)
            paths.removeCache(connection)
            connections = try store.all()
            statuses[connection.id] = nil
            errors[connection.id] = nil
            selection = connections.first?.id
        } catch { alert = error.localizedDescription }
    }

    func toggle(_ connection: Connection, opensFinder: Bool = false) async {
        guard !checkingQuit, canToggle(connection) else { return }
        busy.insert(connection.id)
        errors[connection.id] = nil
        waitingToDisconnect.remove(connection.id)
        defer { busy.remove(connection.id) }
        do {
            let current = await service.status(connection)
            if current.needsReconnect {
                try await service.reconnect(connection, credentials: credentials(for: connection.id))
            } else if current.isActive {
                try await service.unmount(connection)
            } else {
                try await service.mount(connection, credentials: credentials(for: connection.id))
                if opensFinder { openDrive(connection) }
            }
        } catch is UploadsPendingError {
            waitingToDisconnect.insert(connection.id)
        } catch {
            errors[connection.id] = error.localizedDescription
        }
        update(await service.status(connection), for: connection)
    }

    func refreshFiles(_ connection: Connection) async {
        do {
            try await service.refresh(connection)
        } catch { errors[connection.id] = error.localizedDescription }
    }

    func setOpensAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch { alert = error.localizedDescription }
        syncOpensAtLogin()
    }

    private func syncOpensAtLogin() {
        let enabled = SMAppService.mainApp.status == .enabled
        if opensAtLogin != enabled { opensAtLogin = enabled }
    }

    private func connectAutomatically() async {
        for connection in connections where connection.connectsAutomatically && statuses[connection.id]?.isActive == false {
            await toggle(connection)
        }
    }

    func refresh() async {
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
                let status = await service.status(connection)
                if !sleeping, !busy.contains(connection.id) { update(status, for: connection) }
            }
        } while refreshRequested && !sleeping
    }

    func willSleep() { sleeping = true }

    func didWake() async {
        sleeping = false
        await refresh()
    }

    func networkChanged(available: Bool) async {
        networkAvailable = available
        await refresh()
    }

    func canQuit() async -> Bool {
        checkingQuit = true
        defer { checkingQuit = false }
        guard busy.isEmpty else {
            alert = "Wait for the current operation to finish before quitting."
            return false
        }
        for connection in connections where await service.status(connection).isActive {
            alert = "Disconnect your drives before quitting. This keeps pending uploads safe. Closing the window leaves UnlocalFS in the menu bar."
            return false
        }
        return true
    }

    var activity: Activity {
        if statuses.values.contains(where: { $0.pendingUploads > 0 }) { return .syncing }
        return statuses.values.contains(where: \.isMounted) ? .connected : .idle
    }

    func isActive(_ connection: Connection) -> Bool {
        statuses[connection.id]?.isActive == true
    }

    func canToggle(_ connection: Connection) -> Bool {
        !busy.contains(connection.id) && statuses[connection.id] != nil && editor?.id != connection.id
    }

    func canOpen(_ connection: Connection) -> Bool {
        statuses[connection.id]?.isMounted == true && !needsReconnect(connection)
    }

    func canEdit(_ connection: Connection) -> Bool {
        canToggle(connection) && !isActive(connection)
    }

    func statusText(_ connection: Connection) -> String {
        if busy.contains(connection.id) { return "Working…" }
        if needsReconnect(connection) { return "Needs reconnect" }
        if errors[connection.id] != nil { return "Needs attention" }
        guard let status = statuses[connection.id] else { return "Checking…" }
        if status.isActive && !networkAvailable { return "Network unavailable" }
        if status.failedUploads > 0 { return "Upload needs attention" }
        if status.pendingUploads > 0 { return String(AttributedString(localized: "^[\(status.pendingUploads) upload](inflect: true) pending").characters) }
        if status.isMounted { return "Connected" }
        if status.isRunning { return "Ejected · disconnect to stop" }
        return "Disconnected"
    }

    func needsReconnect(_ connection: Connection) -> Bool {
        statuses[connection.id]?.needsReconnect == true
    }

    func toggleTitle(_ connection: Connection) -> String {
        if needsReconnect(connection) { return "Reconnect" }
        return isActive(connection) ? "Disconnect" : "Connect"
    }

    func openDrive(_ connection: Connection) { NSWorkspace.shared.open(paths.mount(connection)) }
    func openLog(_ connection: Connection) { NSWorkspace.shared.open(paths.log(connection)) }
}

private extension AppModel {
    func update(_ status: MountStatus, for connection: Connection) {
        if status.failedUploads > 0, notifiedFailures.insert(connection.id).inserted {
            notify(connection, title: "Uploads failed on \(connection.name)", body: "Some files could not upload. Keep the drive connected while UnlocalFS tries again.")
        }
        if status.isRunning, !status.needsReconnect, status.pendingUploads == 0, status.failedUploads == 0 {
            notifiedFailures.remove(connection.id)
            if waitingToDisconnect.remove(connection.id) != nil {
                notify(connection, title: "\(connection.name) finished uploading", body: "You can disconnect it now.")
            }
        }
        if statuses[connection.id] != status { statuses[connection.id] = status }
    }

    func notify(_ connection: Connection, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                guard try await center.requestAuthorization(options: [.alert]) else { return }
                try await center.add(request)
            } catch {
                Logger().error("Could not show a notification: \(error, privacy: .public)")
            }
        }
    }
}

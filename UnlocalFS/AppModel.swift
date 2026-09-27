import AppKit
import Observation
import UnlocalFSCore

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

    let paths = AppPaths.standard
    let service: MountService
    private let keychain = Keychain()
    private let store: ConnectionStore
    private var refreshing = false
    private var checkingQuit = false

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

    func save(_ connection: Connection, credentials: Credentials) throws {
        try AppError.throwing(credentials.validate())
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
            guard try await !service.status(connection).isActive else { throw AppError("Disconnect this drive before deleting it.") }
            try keychain.delete(connection.id)
            try store.delete(connection.id)
            connections = try store.all()
            statuses[connection.id] = nil
            errors[connection.id] = nil
            selection = connections.first?.id
        } catch { alert = error.localizedDescription }
    }

    func toggle(_ connection: Connection) async {
        guard !checkingQuit, canToggle(connection) else { return }
        busy.insert(connection.id)
        errors[connection.id] = nil
        defer { busy.remove(connection.id) }
        do {
            if try await service.status(connection).isActive {
                try await service.unmount(connection)
            } else {
                try await service.mount(connection, credentials: credentials(for: connection.id))
            }
            statuses[connection.id] = try await service.status(connection)
        } catch { errors[connection.id] = error.localizedDescription }
    }

    func refresh() async {
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false }
        for connection in connections where !busy.contains(connection.id) {
            do {
                let status = try await service.status(connection)
                if !busy.contains(connection.id), statuses[connection.id] != status { statuses[connection.id] = status }
            } catch { errors[connection.id] = error.localizedDescription }
        }
    }

    func canQuit() async -> Bool {
        checkingQuit = true
        defer { checkingQuit = false }
        guard busy.isEmpty else {
            alert = "Wait for the current operation to finish before quitting."
            return false
        }
        for connection in connections {
            do {
                if try await service.status(connection).isActive {
                    alert = "Disconnect your drives before quitting. This keeps pending uploads safe. Closing the window leaves UnlocalFS in the menu bar."
                    return false
                }
            } catch {
                alert = "Could not check \(connection.name). Open its log and check the drive before quitting.\n\n\(error.localizedDescription)"
                return false
            }
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

    func canEdit(_ connection: Connection) -> Bool {
        canToggle(connection) && !isActive(connection)
    }

    func statusText(_ connection: Connection) -> String {
        if busy.contains(connection.id) { return "Working…" }
        if errors[connection.id] != nil { return "Needs attention" }
        guard let status = statuses[connection.id] else { return "Checking…" }
        if status.failedUploads > 0 { return "Upload needs attention" }
        if status.pendingUploads > 0 { return String(AttributedString(localized: "^[\(status.pendingUploads) upload](inflect: true) pending").characters) }
        if status.isMounted { return "Connected" }
        if status.isRunning { return "Ejected · disconnect to stop" }
        return "Disconnected"
    }

    func openDrive(_ connection: Connection) { NSWorkspace.shared.open(paths.mount(connection)) }
    func openLog(_ connection: Connection) { NSWorkspace.shared.open(paths.log(connection)) }
}

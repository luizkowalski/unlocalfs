import Foundation
import UnlocalFSDomain

extension AppViewModel {
    public var activity: Activity {
        if statuses.values.contains(where: { $0.pendingUploads > 0 }) { return .syncing }
        return statuses.values.contains(where: \.isMounted) ? .connected : .idle
    }

    public func isActive(_ connection: Connection) -> Bool {
        statuses[connection.id]?.isActive == true
    }

    public func servingStatus(_ connection: Connection) -> MountStatus? {
        guard let status = statuses[connection.id], status.isRunning, !status.needsReconnect else { return nil }
        return status
    }

    public func problem(_ connection: Connection) -> String? {
        errors[connection.id] ?? statuses[connection.id]?.controlError
    }

    public func canToggle(_ connection: Connection) -> Bool {
        !busy.contains(connection.id) && statuses[connection.id] != nil && editor?.id != connection.id
    }

    public func canConnect(_ connection: Connection) -> Bool {
        canToggle(connection) && !isActive(connection)
    }

    public func canDisconnect(_ connection: Connection) -> Bool {
        canToggle(connection) && isActive(connection) && !needsReconnect(connection)
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
        if isOffline(connection) { return .offline }
        if status.failedUploads > 0 { return .uploadFailed }
        if status.pendingUploads > 0 { return .uploading(status.pendingUploads) }
        if status.isMounted { return .connected }
        if status.isRunning { return .ejected }
        return .disconnected
    }
}

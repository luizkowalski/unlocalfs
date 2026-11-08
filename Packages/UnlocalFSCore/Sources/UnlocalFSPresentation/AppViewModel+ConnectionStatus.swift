import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func driveCondition(_ connection: Connection) -> DriveCondition {
        DriveCondition(
            statuses[connection.id], busy: busy.contains(connection.id), error: errors[connection.id],
            networkAvailable: networkAvailable,
        )
    }

    var activity: Activity {
        if statuses.values.contains(where: { $0.pendingUploads > 0 }) { return .uploading }
        if statuses.values.contains(where: \.isDownloading) { return .downloading }
        return statuses.values.contains(where: \.isMounted) ? .connected : .idle
    }

    func isActive(_ connection: Connection) -> Bool {
        statuses[connection.id]?.isActive == true
    }

    func isDisconnected(_ connection: Connection) -> Bool {
        statuses[connection.id].map { !$0.isActive } ?? false
    }

    func servingStatus(_ connection: Connection) -> MountStatus? {
        guard let status = statuses[connection.id], status.isServing else { return nil }
        return status
    }

    func uploadFailure(_ connection: Connection) -> MountStatus? {
        guard !busy.contains(connection.id), !isOffline(connection),
              let status = servingStatus(connection), status.failedUploads > 0 else { return nil }
        return status
    }

    func problem(_ connection: Connection) -> String? {
        errors[connection.id] ?? statuses[connection.id]?.controlError
    }

    func canToggle(_ connection: Connection) -> Bool {
        !busy.contains(connection.id) && statuses[connection.id] != nil && editor?.id != connection.id
    }

    func canConnect(_ connection: Connection) -> Bool {
        canToggle(connection) && !isActive(connection)
    }

    func canDisconnect(_ connection: Connection) -> Bool {
        canToggle(connection) && isActive(connection) && !needsReconnect(connection)
    }

    func canOpen(_ connection: Connection) -> Bool {
        statuses[connection.id]?.isMounted == true && !needsReconnect(connection)
    }

    func canEdit(_ connection: Connection) -> Bool {
        canToggle(connection) && !isActive(connection)
    }

    func indicator(_ connection: Connection) -> Indicator {
        Indicator(driveCondition(connection), isMounted: statuses[connection.id]?.isMounted == true)
    }

    func statusText(_ connection: Connection) -> String {
        switch driveCondition(connection) {
        case .working: String(localized: .working)
        case .needsReconnect: String(localized: .needsReconnect)
        case .needsAttention: String(localized: .needsAttention)
        case .checking: String(localized: .checking)
        case .offline: String(localized: .networkUnavailable)
        case .uploadFailed: String(localized: .uploadNeedsAttention)
        case let .uploading(count): String(localized: .uploadsPending(count))
        case .connected: String(localized: .connected)
        case .ejected: String(localized: .ejected)
        case .disconnected: String(localized: .disconnected)
        }
    }

    func needsReconnect(_ connection: Connection) -> Bool {
        statuses[connection.id]?.needsReconnect == true
    }

    func toggleTitle(_ connection: Connection) -> String {
        if needsReconnect(connection) { return String(localized: .reconnect) }
        return isActive(connection) ? String(localized: .disconnect) : String(localized: .connect)
    }

    func uploadsBlockingMessage(_ connection: Connection) -> String {
        canOpen(connection) ? String(localized: .uploadsPendingDriveStaysConnected) : String(localized: .uploadsPendingKeepAppRunning)
    }

    func needsMainWindow(_ connection: Connection) -> Bool {
        serverTrust(for: connection) != nil || disconnectFailure?.id == connection.id || uploadsBlockingDisconnect?.id == connection.id
    }
}

public extension AppViewModel.Indicator {
    init(_ condition: DriveCondition, isMounted: Bool) {
        switch condition {
        case .working: self = .working
        case .needsReconnect, .needsAttention, .offline, .uploadFailed: self = .attention
        case .connected: self = .connected
        case .uploading: self = isMounted ? .connected : .idle
        case .checking, .ejected, .disconnected: self = .idle
        }
    }
}

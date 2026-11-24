import Foundation
import UnlocalFSDomain

public extension AppViewModel {
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
        !checkingQuit && !busy.contains(connection.id) && statuses[connection.id] != nil && editor?.id != connection.id
    }

    func driveToggle(_ connection: Connection) -> DriveToggle {
        if needsReconnect(connection) { return .reconnect }
        return isActive(connection) ? .disconnect : .connect
    }

    func canConnect(_ connection: Connection) -> Bool {
        canToggle(connection) && driveToggle(connection) == .connect
    }

    func canDisconnect(_ connection: Connection) -> Bool {
        canToggle(connection) && driveToggle(connection) == .disconnect
    }

    func canReconnect(_ connection: Connection) -> Bool {
        canToggle(connection) && driveToggle(connection) == .reconnect
    }

    var canStartEditing: Bool { ready && editor == nil }

    var canDisconnectAll: Bool { !disconnectingAll && connections.contains(where: canDisconnect) }

    func canOpen(_ connection: Connection) -> Bool {
        statuses[connection.id]?.isMounted == true && !needsReconnect(connection)
    }

    func canEdit(_ connection: Connection) -> Bool {
        canToggle(connection) && !isActive(connection)
    }

    func driveStatus(_ connection: Connection) -> (text: String, indicator: Indicator) {
        let condition = DriveCondition(
            statuses[connection.id], busy: busy.contains(connection.id), hasError: errors[connection.id] != nil,
            offline: isOffline(connection),
        )
        return (condition.statusText, condition.indicator)
    }

    func needsReconnect(_ connection: Connection) -> Bool {
        statuses[connection.id]?.needsReconnect == true
    }

    func toggleTitle(_ connection: Connection) -> String {
        switch driveToggle(connection) {
        case .connect: String(localized: .connect)
        case .disconnect: String(localized: .disconnect)
        case .reconnect: String(localized: .reconnect)
        }
    }

    func uploadsBlockingMessage(_ connection: Connection) -> String {
        canOpen(connection) ? String(localized: .uploadsPendingDriveStaysConnected) : String(localized: .uploadsPendingKeepAppRunning)
    }

    func needsMainWindow(_ connection: Connection) -> Bool {
        serverTrust(for: connection) != nil || disconnectFailure?.id == connection.id || uploadsBlockingDisconnect?.id == connection.id
    }
}

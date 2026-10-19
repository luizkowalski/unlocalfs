import Foundation
import UnlocalFSDomain

extension AppViewModel {
    public func canCleanUpUploads(_ connection: Connection) -> Bool {
        connection.backend.supportsUploadCleanup && !connection.readOnly && !busy.contains(connection.id) && servingStatus(connection) != nil
    }

    public func reviewUnfinishedUploads(_ connection: Connection) async {
        guard canCleanUpUploads(connection) else { return }
        busy.insert(connection.id)
        defer { busy.remove(connection.id) }
        do {
            let uploads = try await drives.unfinishedUploads(in: connection)
            let now = Date.now
            let abandoned = uploads.count { $0.isAbandoned(at: now) }
            let inFlight = uploads.count - abandoned
            if abandoned > 0 {
                uploadCleanup = UploadCleanup(connection: connection, abandoned: abandoned, inFlight: inFlight)
            } else {
                let nothing = String(localized: .noAbandonedUploads(connection.name))
                alert = inFlight == 0 ? nothing : "\(nothing) \(String(localized: .recentUploadsKept(inFlight)))"
            }
        } catch { alert = error.localizedDescription }
    }

    public func cleanUpUnfinishedUploads(_ cleanup: UploadCleanup) async {
        let connection = cleanup.connection
        guard canCleanUpUploads(connection) else { return }
        busy.insert(connection.id)
        defer { busy.remove(connection.id) }
        do {
            try await drives.removeAbandonedUploads(in: connection)
            let now = Date.now
            let remaining = try await drives.unfinishedUploads(in: connection).count { $0.isAbandoned(at: now) }
            if remaining > 0 {
                alert = String(localized: .abandonedUploadsRemain(remaining))
            } else {
                desktop.notify(
                    title: String(localized: .unfinishedUploadsRemoved(cleanup.abandoned)),
                    body: String(localized: .unfinishedUploadsRemovedBody(connection.name)), fallbackToAlert: false
                )
            }
        } catch { alert = error.localizedDescription }
    }
}

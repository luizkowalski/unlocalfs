import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func canCleanUpUploads(_ connection: Connection) -> Bool {
        canToggle(connection) && connection.backend.supportsUploadCleanup && !connection.readOnly && servingStatus(connection) != nil
    }

    func reviewUnfinishedUploads(_ connection: Connection) async {
        await operate(on: connection, when: canCleanUpUploads(connection)) {
            do {
                let uploads = try await drives.unfinishedUploads(in: connection)
                let now = Date.now
                let abandoned = uploads.count { $0.isAbandoned(at: now) }
                let inFlight = uploads.count - abandoned
                if abandoned > 0 {
                    uploadCleanup = UploadCleanup(connection: connection, abandoned: abandoned, inFlight: inFlight)
                } else {
                    alert = AppAlert(
                        String(localized: .nothingToCleanUp),
                        UploadCleanup.describe(String(localized: .noAbandonedUploads(connection.name)), keeping: inFlight),
                    )
                }
            } catch { alert = AppAlert(String(localized: .uploadsNotChecked(connection.name)), error) }
        }
    }

    func cleanUpUnfinishedUploads(_ cleanup: UploadCleanup) async {
        let connection = cleanup.connection
        await operate(on: connection, when: canCleanUpUploads(connection)) {
            do {
                try await drives.removeAbandonedUploads(in: connection)
                let now = Date.now
                let remaining = try await drives.unfinishedUploads(in: connection).count { $0.isAbandoned(at: now) }
                if remaining > 0 {
                    alert = AppAlert(String(localized: .uploadsNotRemoved), String(localized: .abandonedUploadsRemain(remaining)))
                } else {
                    desktop.notify(
                        title: String(localized: .unfinishedUploadsRemoved(cleanup.abandoned)),
                        body: String(localized: .unfinishedUploadsRemovedBody(connection.name)), fallbackToAlert: false,
                    )
                }
            } catch { alert = AppAlert(String(localized: .uploadsNotRemoved), error) }
        }
    }
}

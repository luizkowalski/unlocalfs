import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct DriveManagementItems: View {
    @Environment(AppViewModel.self) private var model
    let connection: Connection
    var hidesUnavailable = false

    var body: some View {
        let canEdit = model.canEdit(connection)
        let canCleanUp = model.canCleanUpUploads(connection)
        if canEdit || !hidesUnavailable {
            Button("Edit Connection…") { model.edit(connection) }
                .disabled(!canEdit)
        }
        Button("Duplicate…") { model.duplicate(connection) }
        if connection.exportsRcloneConfig {
            Button("Export rclone Config…") { Task { await model.exportRcloneConfig(connection) } }
        }
        if connection.backend.supportsUploadCleanup, canCleanUp || !hidesUnavailable {
            Button("Clean Up Unfinished Uploads…") { Task { await model.reviewUnfinishedUploads(connection) } }
                .disabled(!canCleanUp)
        }
        Button("Show Log") { model.openLog(connection) }
        if canEdit || !hidesUnavailable {
            Divider()
            Button("Delete…", role: .destructive) { model.deleting = connection }
                .disabled(!canEdit)
        }
    }
}

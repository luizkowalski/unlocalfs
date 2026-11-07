import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct DriveManagementItems: View {
    @Environment(AppViewModel.self) private var model
    let connection: Connection

    var body: some View {
        Button("Edit Connection") { model.edit(connection) }
            .disabled(!model.canEdit(connection))
        Button("Duplicate") { model.duplicate(connection) }
        if model.offersRcloneConfigExport(connection) {
            Button("Export rclone Config…") { Task { await model.exportRcloneConfig(connection) } }
        }
        if model.offersUploadCleanup(connection) {
            Button("Clean Up Unfinished Uploads…") { Task { await model.reviewUnfinishedUploads(connection) } }
                .disabled(!model.canCleanUpUploads(connection))
        }
        Button("Show Log") { model.openLog(connection) }
        Divider()
        Button("Delete…", role: .destructive) { model.deleting = connection }
            .disabled(!model.canEdit(connection))
    }
}

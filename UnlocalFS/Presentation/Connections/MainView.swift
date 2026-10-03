import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct MainView: View {
    @Environment(AppViewModel.self) private var model
    @Environment(ViewModelFactory.self) private var viewModels

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            List(selection: $model.selection) {
                Section("Unlocals") {
                    ForEach(model.connections) { ConnectionRow(connection: $0) }
                }
            }
            .contextMenu(forSelectionType: UUID.self) { _ in
            } primaryAction: { ids in
                if let connection = model.connections.first(where: { ids.contains($0.id) }) {
                    Task { await model.activate(connection) }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 230)
            .safeAreaInset(edge: .bottom) {
                Button("Add connection", systemImage: "plus") { model.edit(Connection()) }
                    .buttonStyle(.borderless)
                    .disabled(!model.ready)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        } detail: {
            if let connection = model.selected {
                ConnectionDetail(connection: connection)
            } else {
                ContentUnavailableView {
                    Label("Your storage, in Finder", systemImage: "externaldrive.badge.icloud")
                } description: {
                    Text("Connect an S3 bucket or an SFTP server and use its files from your Mac.")
                } actions: {
                    Button("Add Connection") { model.edit(Connection()) }
                        .buttonStyle(.borderedProminent)
                        .disabled(!model.ready)
                }
            }
        }
        .frame(minWidth: 720, minHeight: 680)
        .sheet(item: $model.editor) { ConnectionEditor(viewModel: viewModels.makeEditor($0)) }
        .alert("UnlocalFS", isPresented: $model.isShowingAlert, presenting: model.alert) { _ in
            Button("OK", role: .cancel) {}
        } message: {
            Text($0)
        }
        .confirmationDialog(
            "Delete \(model.deleting?.name ?? "connection")?",
            isPresented: $model.isConfirmingDelete,
            titleVisibility: .visible,
            presenting: model.deleting
        ) { connection in
            Button("Delete Connection", role: .destructive) { Task { await model.delete(connection) } }
        } message: { _ in
            Text("This removes the saved connection, credentials, and local file cache. Remote files are kept.")
        }
    }
}

private struct ConnectionRow: View {
    @Environment(AppViewModel.self) private var model
    let connection: Connection

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(connection.name)
                    if connection.encrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .help("Encrypted drive")
                            .accessibilityLabel("Encrypted drive")
                    }
                }
                Text(model.statusText(connection)).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } icon: {
            if model.needsReconnect(connection) {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
            } else if model.isActive(connection) {
                Image(systemName: "externaldrive.fill.badge.icloud")
            } else {
                Image(systemName: "externaldrive").foregroundStyle(.secondary)
            }
        }
        .tag(connection.id)
        .contextMenu {
            Button("Open in Finder") { model.openDrive(connection) }
                .disabled(!model.canOpen(connection))
            Button("Refresh Files") { Task { await model.refreshFiles(connection) } }
                .disabled(!model.canOpen(connection))
            if model.needsReconnect(connection) {
                Button("Reconnect") { Task { await model.toggle(connection) } }
                    .disabled(!model.canToggle(connection))
            }
            Divider()
            Button("Edit Connection") { model.edit(connection) }
                .disabled(!model.canEdit(connection))
            Button("Duplicate") { model.duplicate(connection) }
            if connection.encrypted {
                Button("Export rclone Config…") { Task { await model.exportRcloneConfig(connection) } }
            }
            Divider()
            Button("Delete…", role: .destructive) { model.deleting = connection }
                .disabled(!model.canEdit(connection))
        }
    }
}

import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct MainView: View {
    @Environment(AppViewModel.self) private var model
    @Environment(ViewModelFactory.self) private var viewModels
    @State private var traffic: TrafficViewModel?

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 720, minHeight: 680)
        .task {
            let traffic = viewModels.makeTraffic()
            traffic.reload()
            self.traffic = traffic
        }
        .onChange(of: model.statuses.mapValues(\.unsavedTraffic)) { traffic?.reload() }
        .onChange(of: model.connections) { traffic?.reload() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in traffic?.reload() }
        .sheet(item: $model.editor) { ConnectionEditor(viewModel: viewModels.makeEditor($0)) }
        .alert("UnlocalFS", isPresented: $model.isShowingAlert, presenting: model.alert) { _ in
            Button("OK", role: .cancel) {}
        } message: {
            Text($0)
        }
        .alert("“\(model.disconnectFailure?.name ?? "")” couldn’t be disconnected.",
               isPresented: $model.isShowingDisconnectFailure, presenting: model.disconnectFailure) { connection in
            Button("Keep Connected", role: .cancel) {}
            Button("Try Disconnect Again") { Task { await model.disconnect(connection) } }
        } message: { _ in
            Text("Close files and stop apps using this drive, then try again. The drive is still connected.")
        }
        .alert("“\(model.uploadsBlockingDisconnect?.name ?? "")” is still uploading files.",
               isPresented: $model.isShowingUploadsBlockingDisconnect, presenting: model.uploadsBlockingDisconnect) { _ in
            Button("OK", role: .cancel) {}
        } message: { connection in
            Text(model.uploadsBlockingMessage(connection))
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
        .confirmationDialog(
            model.uploadCleanup?.title ?? "",
            item: $model.uploadCleanup,
            titleVisibility: .visible
        ) { cleanup in
            Button("Remove Uploads", role: .destructive) { Task { await model.cleanUpUnfinishedUploads(cleanup) } }
        } message: { cleanup in
            Text(cleanup.message)
        }
    }

    private var sidebar: some View {
        @Bindable var model = model
        return List(selection: $model.selection) {
            Section("Unlocals") {
                ForEach(model.connections) { ConnectionRow(connection: $0) }
            }
        }
        .contextMenu(forSelectionType: AppViewModel.SidebarItem.self) { _ in
        } primaryAction: { items in
            if let connection = model.connections.first(where: { items.contains(.drive($0.id)) }) {
                Task { await model.activate(connection) }
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 230)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                if let traffic {
                    TrafficCard(viewModel: traffic, isSelected: model.selection == .traffic) { model.selection = .traffic }
                }
                Button("Add connection", systemImage: "plus") { model.edit(Connection()) }
                    .buttonStyle(.borderless)
                    .disabled(!model.ready)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    @ViewBuilder private var detail: some View {
        if model.selection == .traffic {
            if let traffic { TrafficView(viewModel: traffic) }
        } else if let connection = model.selected {
            ConnectionDetail(connection: connection)
        } else {
            ContentUnavailableView {
                Label("Your storage, in Finder", systemImage: "externaldrive.badge.icloud")
            } description: {
                Text("Connect an S3 or Google Cloud Storage bucket, or an SFTP server, and use its files from your Mac.")
            } actions: {
                Button("Add Connection") { model.edit(Connection()) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.ready)
            }
        }
    }
}

private struct ConnectionRow: View {
    @Environment(AppViewModel.self) private var model
    let connection: Connection

    private var icon: some View {
        ProviderIcon(provider: connection.provider, size: 20)
            .foregroundStyle(model.isActive(connection) ? .primary : .secondary)
    }

    var body: some View {
        HStack(spacing: 10) {
            icon.frame(width: 24)
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
            Spacer(minLength: 0)
            StatusIndicator(indicator: model.indicator(connection), showsIdle: false)
                .frame(width: 12)
                .accessibilityHidden(true)
        }
        .tag(AppViewModel.SidebarItem.drive(connection.id))
        .contextMenu {
            Button("Connect") { Task { await model.activate(connection) } }
                .disabled(!model.canConnect(connection))
            Button("Disconnect") { Task { await model.disconnect(connection) } }
                .disabled(!model.canDisconnect(connection))
            Button("Disconnect All") { Task { await model.disconnectAll() } }
            if model.needsReconnect(connection) {
                Button("Reconnect") { Task { await model.toggle(connection) } }
                    .disabled(!model.canToggle(connection))
            }
            Divider()
            Button("Open in Finder") { model.openDrive(connection) }
                .disabled(!model.canOpen(connection))
            Button("Refresh Files") { Task { await model.refreshFiles(connection) } }
                .disabled(!model.canOpen(connection))
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

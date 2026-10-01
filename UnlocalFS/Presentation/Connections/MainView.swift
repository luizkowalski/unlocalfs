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
                    Text("Connect an S3 bucket and use its files from your Mac.")
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
            Divider()
            Button("Delete…", role: .destructive) { model.deleting = connection }
                .disabled(!model.canEdit(connection))
        }
    }
}

private struct ConnectionDetail: View {
    @Environment(AppViewModel.self) private var model
    let connection: Connection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                HStack {
                    Button(model.toggleTitle(connection)) {
                        Task { await model.toggle(connection, opensFinder: true) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canToggle(connection))
                    Button("Open in Finder") { model.openDrive(connection) }
                        .disabled(!model.canOpen(connection))
                    Button("Refresh Files") { Task { await model.refreshFiles(connection) } }
                        .disabled(!model.canOpen(connection))
                        .help("Show changes made to this drive from other apps or Macs")
                }
                if model.isOffline(connection) {
                    Label("Network unavailable. Cached files are kept.", systemImage: "wifi.slash")
                        .font(.callout).foregroundStyle(.secondary)
                }
                if let problem = model.problem(connection) {
                    errorBox(problem)
                } else if let notice = model.uploadNotice(connection) {
                    Label(notice, systemImage: "info.circle")
                        .font(.callout).foregroundStyle(.secondary)
                }
                if model.isServing(connection) {
                    ActivityView(connection: connection)
                }
                GroupBox("Connection") {
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                        row("Provider", Label { Text(connection.provider.title) } icon: { connection.provider.logo })
                        row("Bucket", Text(connection.bucket))
                        if !connection.folder.isEmpty {
                            row("Folder", Text(connection.folder))
                        }
                        row("Endpoint", Text(connection.endpoint))
                        row("Region", connection.region.isEmpty ? Text("Default") : Text(connection.region))
                        row("Encrypted", connection.encrypted ? Text("Yes") : Text("No"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                }
                GroupBox("On this Mac") {
                    VStack(alignment: .leading, spacing: 14) {
                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                            row("Drive", Text(tildePath(model.mountLocation(connection))))
                            row("Cache", Text(tildePath(model.cacheLocation(connection))))
                            if let cached = model.cachedBytes(connection) {
                                row("Cache size", HStack(spacing: 12) {
                                    ProgressView(value: Double(cached), total: Double(connection.cacheLimit))
                                        .tint(.green)
                                        .frame(maxWidth: 240)
                                        .accessibilityLabel("Cache size")
                                    Text("\(cached, format: .byteCount(style: .file)) of \(connection.cacheLimit, format: .byteCount(style: .file))")
                                })
                            } else {
                                row("Cache limit", Text(connection.cacheLimit, format: .byteCount(style: .file)))
                            }
                            if connection.minimumFreeSpace > 0 {
                                row("Keep free", Text(connection.minimumFreeSpace, format: .byteCount(style: .file)))
                            }
                        }
                        Text("Files upload after you close them. Keep the drive connected until pending uploads finish.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                }
            }
            .padding(28)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Edit Connection") { model.edit(connection) }
                    .disabled(!model.canEdit(connection))
                Button("Duplicate") { model.duplicate(connection) }
                Button("Open Log") { model.openLog(connection) }
                Spacer()
                Button("Delete…", role: .destructive) { model.deleting = connection }
                    .disabled(!model.canEdit(connection))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(.bar)
        }
        .navigationTitle(connection.name)
    }

    private var header: some View {
        HStack(spacing: 16) {
            logo
                .frame(width: 40, height: 40)
                .foregroundStyle(.tint)
                .accessibilityLabel(connection.provider.title)
            VStack(alignment: .leading, spacing: 5) {
                Text(connection.name).font(.largeTitle.bold())
                HStack(spacing: 6) {
                    switch model.indicator(connection) {
                    case .working: ProgressView().controlSize(.small)
                    case .attention: Circle().fill(Color.orange).frame(width: 7, height: 7)
                    case .connected: Circle().fill(Color.green).frame(width: 7, height: 7)
                    case .idle: Circle().fill(Color.secondary).frame(width: 7, height: 7)
                    }
                    Text(model.statusText(connection)).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder private var logo: some View {
        if connection.provider == .other {
            connection.provider.logo.font(.system(size: 40, weight: .light))
        } else {
            connection.provider.logo.resizable().scaledToFit()
        }
    }

    private func errorBox(_ error: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("Connection needs attention", systemImage: "exclamationmark.triangle").font(.headline)
                Text(error).font(.callout).textSelection(.enabled)
                HStack {
                    Button("Check Again") { Task { await model.checkAgain(connection) } }
                    Button("Open Log") { model.openLog(connection) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(6)
        }
    }

    private func tildePath(_ url: URL) -> String {
        (url.path(percentEncoded: false) as NSString).abbreviatingWithTildeInPath
    }

    private func row(_ label: LocalizedStringKey, _ value: some View) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary)
            value.textSelection(.enabled)
        }
    }
}

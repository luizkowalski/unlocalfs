import SwiftUI
import UnlocalFSCore

struct MainView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            List(selection: $model.selection) {
                Section("Connections") {
                    ForEach(model.connections) { ConnectionRow(connection: $0) }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 230)
            .safeAreaInset(edge: .bottom) {
                Button("Add connection", systemImage: "plus") { model.editor = Connection() }
                    .buttonStyle(.borderless)
                    .disabled(!model.ready)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        } detail: {
            if let connection = model.connections.first(where: { $0.id == model.selection }) {
                ConnectionDetail(connection: connection)
            } else {
                ContentUnavailableView {
                    Label("Your storage, in Finder", systemImage: "externaldrive.badge.icloud")
                } description: {
                    Text("Connect an S3 bucket and use its files from your Mac.")
                } actions: {
                    Button("Add Connection") { model.editor = Connection() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!model.ready)
                }
            }
        }
        .frame(minWidth: 720, minHeight: 500)
        .sheet(item: $model.editor) { ConnectionEditor(connection: $0) }
        .alert("UnlocalFS", isPresented: $model.isShowingAlert, presenting: model.alert) { _ in
            Button("OK", role: .cancel) {}
        } message: {
            Text($0)
        }
        .confirmationDialog("Delete \(model.deleting?.name ?? "connection")?", isPresented: $model.isConfirmingDelete, titleVisibility: .visible, presenting: model.deleting) { connection in
            Button("Delete Connection", role: .destructive) { Task { await model.delete(connection) } }
        } message: { _ in
            Text("This removes the saved connection and credentials. Remote files and the local file cache are kept.")
        }
    }
}

private struct ConnectionRow: View {
    @Environment(AppModel.self) private var model
    let connection: Connection

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(connection.name)
                Text(model.statusText(connection)).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } icon: {
            if model.isActive(connection) {
                Image(systemName: "externaldrive.fill.badge.icloud")
            } else {
                Image(systemName: "externaldrive").foregroundStyle(.secondary)
            }
        }
        .tag(connection.id)
    }
}

private struct ConnectionDetail: View {
    @Environment(AppModel.self) private var model
    let connection: Connection

    private var status: MountStatus? { model.statuses[connection.id] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                HStack {
                    Button(model.isActive(connection) ? "Disconnect" : "Connect") {
                        Task { await model.toggle(connection) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canToggle(connection))
                    Button("Open in Finder") { model.openDrive(connection) }
                        .disabled(status?.isMounted != true)
                }
                if let error = model.errors[connection.id] {
                    errorBox(error)
                }
                GroupBox("Connection") {
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                        row("Provider", connection.provider.title)
                        row("Bucket", connection.bucket)
                        row("Endpoint", connection.endpoint)
                        row("Region", connection.region.isEmpty ? "Default" : connection.region)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                }
                GroupBox("On this Mac") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(model.paths.mount(connection).path).textSelection(.enabled)
                        if let status, status.isRunning {
                            Text("\(status.bytesCached.formatted(.byteCount(style: .file))) cached locally")
                                .foregroundStyle(.secondary)
                        }
                        Text("Files upload after you close them. Keep the drive connected until pending uploads finish.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                }
                HStack {
                    Button("Edit Connection") { model.editor = connection }
                        .disabled(!model.canEdit(connection))
                    Button("Open Log") { model.openLog(connection) }
                    Spacer()
                    Button("Delete…", role: .destructive) { model.deleting = connection }
                        .disabled(!model.canEdit(connection))
                }
            }
            .padding(28)
        }
        .navigationTitle(connection.name)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: "externaldrive.badge.icloud")
                .font(.system(size: 40, weight: .light)).foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 5) {
                Text(connection.name).font(.largeTitle.bold())
                HStack(spacing: 6) {
                    if model.busy.contains(connection.id) {
                        ProgressView().controlSize(.small)
                    } else {
                        Circle().fill(status?.isMounted == true ? Color.green : Color.secondary).frame(width: 7, height: 7)
                    }
                    Text(model.statusText(connection)).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private func errorBox(_ error: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("Connection needs attention", systemImage: "exclamationmark.triangle").font(.headline)
                Text(error).font(.callout).textSelection(.enabled)
                HStack {
                    Button("Check Again") {
                        model.errors[connection.id] = nil
                        Task { await model.refresh() }
                    }
                    Button("Open Log") { model.openLog(connection) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(6)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
        }
    }
}

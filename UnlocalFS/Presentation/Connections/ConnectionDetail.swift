import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ConnectionDetail: View {
    @Environment(AppViewModel.self) private var model
    let connection: Connection

    var body: some View {
        let status = model.servingStatus(connection)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let problem = model.problem(connection) {
                    problemBanner(problem)
                }
                header(status)
                CacheUsage(status: status, limit: connection.cacheLimit)
                if model.isOffline(connection) {
                    Label("Network unavailable. Cached files are kept.", systemImage: "wifi.slash")
                        .font(.callout).foregroundStyle(.secondary)
                } else if let notice = model.uploadNotice(connection) {
                    Label(notice, systemImage: "info.circle")
                        .font(.callout).foregroundStyle(.secondary)
                }
                details(status)
                if status != nil {
                    ActivityView(connection: connection)
                }
            }
            .padding(28)
        }
        .safeAreaInset(edge: .top, spacing: 0) { actions }
        .navigationTitle(connection.name)
    }

    private var actions: some View {
        HStack(spacing: 2) {
            Button(model.toggleTitle(connection), systemImage: "power") {
                Task { await model.toggle(connection, opensFinder: true) }
            }
            .disabled(!model.canToggle(connection))
            Button("Open", systemImage: "folder") { model.openDrive(connection) }
                .disabled(!model.canOpen(connection))
                .help("Open in Finder")
            Button("Refresh", systemImage: "arrow.clockwise") { Task { await model.refreshFiles(connection) } }
                .disabled(!model.canOpen(connection))
                .help("Show changes made to this drive from other apps or Macs")
            Button("Edit", systemImage: "pencil") { model.edit(connection) }
                .disabled(!model.canEdit(connection))
            Button("Duplicate", systemImage: "plus.square.on.square") { model.duplicate(connection) }
            if connection.encrypted {
                Button("Export", systemImage: "square.and.arrow.up") { Task { await model.exportRcloneConfig(connection) } }
                    .help("Save a file that lets rclone read this drive without UnlocalFS")
            }
            Button("Log", systemImage: "doc.text") { model.openLog(connection) }
            Spacer()
            Button("Delete", systemImage: "trash", role: .destructive) { model.deleting = connection }
                .disabled(!model.canEdit(connection))
        }
        .buttonStyle(ToolButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func header(_ status: MountStatus?) -> some View {
        HStack(spacing: 16) {
            logo
                .frame(width: 34, height: 34)
                .foregroundStyle(.tint)
                .frame(width: 56, height: 56)
                .background(.tint.opacity(0.12), in: .rect(cornerRadius: 12))
                .accessibilityLabel(connection.provider.title)
            VStack(alignment: .leading, spacing: 3) {
                Text(connection.name).font(.title2.weight(.semibold))
                Text(verbatim: "\(connection.provider.title) · \(connection.bucket)").foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    switch model.indicator(connection) {
                    case .working: ProgressView().controlSize(.mini)
                    case .attention: Circle().fill(Color.orange).frame(width: 7, height: 7)
                    case .connected: Circle().fill(Color.green).frame(width: 7, height: 7)
                    case .idle: Circle().fill(Color.secondary).frame(width: 7, height: 7)
                    }
                    Text(model.statusText(connection)).foregroundStyle(.secondary)
                }
                .font(.callout)
            }
            Spacer()
            if let status {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(status.bytesCached, format: .size).font(.title2.weight(.medium))
                    Text("cached of \(connection.cacheLimit, format: .size)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .monospacedDigit()
            }
        }
    }

    @ViewBuilder private var logo: some View {
        if connection.provider == .other {
            connection.provider.logo.font(.system(size: 30, weight: .light))
        } else {
            connection.provider.logo.resizable().scaledToFit()
        }
    }

    private func details(_ status: MountStatus?) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
                detail("Mount point") { Text(tildePath(model.mountLocation(connection))) }
                Divider()
                detail("Read-only") { connection.readOnly ? Text("On") : Text("Off") }
                Divider()
                detail("Cache limit") { Text(connection.cacheLimit, format: .size) }
                Divider()
                detail("Keep free") {
                    connection.minimumFreeSpace > 0
                        ? Text(connection.minimumFreeSpace, format: .size)
                        : Text("Not set")
                }
            }
            .padding(.horizontal, 14)
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
                detail("Bucket") { Text(connection.folder.isEmpty ? connection.bucket : "\(connection.bucket)/\(connection.folder)") }
                Divider()
                detail("Endpoint") { Text(connection.endpoint).help(connection.endpoint) }
                Divider()
                detail("Region") { connection.region.isEmpty ? Text("Default") : Text(connection.region) }
                Divider()
                detail("Encryption") { connection.encrypted ? Text("On") : Text("Off") }
            }
            .padding(.horizontal, 14)
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator) }
    }

    private func detail(_ label: LocalizedStringKey, @ViewBuilder value: () -> some View) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary).frame(minHeight: 34)
            value()
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func problemBanner(_ problem: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").font(.title3).foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 6) {
                Text("Connection needs attention").font(.headline)
                Text(problem).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                Button("Check Again") { Task { await model.checkAgain(connection) } }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12), in: .rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(Color.orange.opacity(0.3)) }
    }

    private func tildePath(_ url: URL) -> String {
        (url.path(percentEncoded: false) as NSString).abbreviatingWithTildeInPath
    }
}

private struct CacheUsage: View {
    let status: MountStatus?
    let limit: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    Rectangle().fill(.green).frame(width: proxy.size.width * share(cached))
                    Rectangle().fill(.blue).frame(width: proxy.size.width * share(pending))
                }
            }
            .frame(height: 22)
            .background(.quaternary)
            .clipShape(.rect(cornerRadius: 5))
            .accessibilityHidden(true)
            HStack(alignment: .top, spacing: 28) {
                legend("Cached files", color: .green) { _ in Text(cached, format: .size) }
                legend("Waiting to upload", color: .blue) {
                    $0.pendingUploads > 0
                        ? Text("\($0.pendingBytes, format: .size) · ^[\($0.pendingUploads) file](inflect: true)")
                        : Text("None")
                }
                legend("Free cache", color: .secondary.opacity(0.4)) { _ in Text(free, format: .size) }
            }
        }
    }

    private var pending: Int64 { status?.pendingBytes ?? 0 }
    private var cached: Int64 { max((status?.bytesCached ?? 0) - pending, 0) }
    private var free: Int64 { max(limit - (status?.bytesCached ?? 0), 0) }

    private func share(_ bytes: Int64) -> Double {
        Double(bytes) / Double(max(limit, cached + pending))
    }

    private func legend(_ title: LocalizedStringKey, color: Color, value: (MountStatus) -> Text) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                (status.map(value) ?? Text(verbatim: "—"))
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ToolButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(ToolLabelStyle())
            .foregroundStyle(configuration.role == .destructive ? Color.red : Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(configuration.isPressed ? 1 : 0), in: .rect(cornerRadius: 6))
            .contentShape(.rect)
            .opacity(isEnabled ? 1 : 0.35)
    }
}

private struct ToolLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 3) {
            configuration.icon.font(.system(size: 15)).frame(height: 18)
            configuration.title.font(.caption).foregroundStyle(.secondary)
        }
    }
}

private extension FormatStyle where Self == ByteCountFormatStyle {
    static var size: Self { .byteCount(style: .file, spellsOutZero: false) }
}

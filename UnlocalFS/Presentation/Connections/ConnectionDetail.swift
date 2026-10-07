import AppKit
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
                header
                if model.isOffline(connection) {
                    Label("Network unavailable. Cached files are kept.", systemImage: "wifi.slash")
                        .font(.callout).foregroundStyle(.secondary)
                }
                if status != nil {
                    ActivityView(connection: connection, notice: model.uploadNotice(connection))
                }
                details
            }
            .padding(28)
        }
        .safeAreaInset(edge: .top, spacing: 0) { actions }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let status { cacheFooter(status) }
        }
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

    private var header: some View {
        HStack(spacing: 16) {
            logo
                .frame(width: 34, height: 34)
                .foregroundStyle(.tint)
                .frame(width: 56, height: 56)
                .background(.tint.opacity(0.12), in: .rect(cornerRadius: 12))
                .accessibilityLabel(connection.provider.title)
            VStack(alignment: .leading, spacing: 3) {
                Text(connection.name).font(.title2.weight(.semibold))
                Text(verbatim: "\(connection.provider.title) · \(storageName)").foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    StatusIndicator(indicator: model.indicator(connection))
                    Text(model.statusText(connection)).foregroundStyle(.secondary)
                }
                .font(.callout)
            }
        }
    }

    private func cacheFooter(_ status: MountStatus) -> some View {
        Text("\(status.bytesCached, format: .size) cached on this Mac. When the cache is full, the oldest copies are cleared.")
            .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            .background(.bar)
            .overlay(alignment: .top) { Divider() }
    }

    @ViewBuilder private var logo: some View {
        if connection.provider == .other {
            connection.provider.logo.font(.system(size: 30, weight: .light))
        } else {
            connection.provider.logo.resizable().scaledToFit()
        }
    }

    private var details: some View {
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
                switch connection.backend {
                case .gcs:
                    bucketDetail
                case .s3Compatible:
                    bucketDetail
                    Divider()
                    detail("Endpoint") { copyable(connection.endpoint) }
                    Divider()
                    detail("Region") { connection.region.isEmpty ? Text("Default") : Text(connection.region) }
                case .sftp:
                    sftpDetails
                }
                Divider()
                detail("Encryption") { connection.encrypted ? Text("On") : Text("Off") }
            }
            .padding(.horizontal, 14)
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator) }
    }

    private var storageName: String {
        switch connection.backend {
        case .s3Compatible, .gcs: connection.bucket
        case .sftp: connection.sftp.host
        }
    }

    private var bucketDetail: some View {
        detail("Bucket") { Text(connection.bucketPath) }
    }

    @ViewBuilder private var sftpDetails: some View {
        let sftp = connection.sftp
        let server = "\(sftp.username)@\(sftp.host):\(sftp.port)"
        detail("Server") { copyable(server) }
        Divider()
        detail("Folder") { sftp.remotePath.isEmpty ? Text("Home folder") : Text(verbatim: sftp.remotePath) }
        Divider()
        detail("Sign in with") { Text(sftp.authentication.title) }
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

    private func copyable(_ value: String) -> some View {
        HStack(spacing: 6) {
            Text(verbatim: value).help(value)
            CopyButton(value: value)
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

private struct CopyButton: View {
    let value: String
    @State private var copied = false

    var body: some View {
        Button("Copy", systemImage: copied ? "checkmark" : "doc.on.doc") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
            copied = true
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .contentTransition(.symbolEffect(.replace, options: .speed(2.5)))
        .help("Copy")
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(for: .seconds(1))
            copied = false
        }
    }
}

private struct ToolButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(ToolLabelStyle(isDestructive: configuration.role == .destructive))
            .foregroundStyle(configuration.role == .destructive ? Color.red : Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(configuration.isPressed ? 1 : 0), in: .rect(cornerRadius: 6))
            .contentShape(.rect)
            .opacity(isEnabled ? 1 : 0.35)
    }
}

private struct ToolLabelStyle: LabelStyle {
    let isDestructive: Bool

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 3) {
            configuration.icon.font(.system(size: 15)).frame(height: 18)
            configuration.title.font(.caption).foregroundStyle(isDestructive ? Color.red : Color.secondary)
        }
    }
}

private extension FormatStyle where Self == ByteCountFormatStyle {
    static var size: Self { .byteCount(style: .file, spellsOutZero: false) }
}

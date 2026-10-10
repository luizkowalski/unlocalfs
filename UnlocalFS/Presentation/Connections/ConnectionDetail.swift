import AppKit
import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ConnectionDetail: View {
    @Environment(AppViewModel.self) private var model
    @Environment(ViewModelFactory.self) private var viewModels
    @State private var activity: ActivityViewModel?
    let connection: Connection

    var body: some View {
        let status = model.servingStatus(connection)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let problem = model.problem(connection) {
                    problemNotice(problem)
                }
                if model.isOffline(connection) {
                    DetailSection {
                        Label("Network unavailable. Cached files are kept.", systemImage: "wifi.slash")
                    }
                }
                if status != nil, let activity {
                    ActivitySection(viewModel: activity)
                }
                details(status)
            }
            .padding(24)
        }
        .labeledContentStyle(.trailingValue)
        .task(id: status == nil ? nil : connection.id) {
            guard status != nil else { return }
            let activity = self.activity ?? viewModels.makeActivity()
            self.activity = activity
            await activity.observe(connection)
        }
        .toolbar { actions }
        .navigationTitle(connection.name)
        .sheet(item: Binding(get: { model.serverTrust[connection.id] }, set: { _ in })) { challenge in
            ServerTrustSheet(challenge: challenge,
                             onTrust: { Task { await model.trustServer(connection) } },
                             onCancel: { Task { await model.cancelServerTrust(connection) } })
        }
    }

    @ToolbarContentBuilder private var actions: some ToolbarContent {
        ToolbarItemGroup {
            Button(model.toggleTitle(connection), systemImage: "power") {
                Task { await model.toggle(connection, opensFinder: true) }
            }
            .disabled(!model.canToggle(connection))
            .help(model.toggleTitle(connection))
            Button("Open", systemImage: "folder") { model.openDrive(connection) }
                .disabled(!model.canOpen(connection))
                .help("Open in Finder")
            Button("Refresh", systemImage: "arrow.clockwise") { Task { await model.refreshFiles(connection) } }
                .disabled(!model.canOpen(connection))
                .help("Show changes made to this drive from other apps or Macs")
        }
        if #available(macOS 26, *) {
            ToolbarSpacer(.fixed)
        }
        ToolbarItem {
            Menu("More", systemImage: "ellipsis") {
                Button("Edit Connection") { model.edit(connection) }
                    .disabled(!model.canEdit(connection))
                Button("Duplicate") { model.duplicate(connection) }
                if connection.encrypted {
                    Button("Export rclone Config…") { Task { await model.exportRcloneConfig(connection) } }
                }
                Button("Show Log") { model.openLog(connection) }
                Divider()
                Button("Delete…", role: .destructive) { model.deleting = connection }
                    .disabled(!model.canEdit(connection))
            }
            .menuIndicator(.hidden)
            .help("More")
        }
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
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(connection.name).font(.title2.weight(.semibold))
                    if connection.encrypted {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .help("Encrypted drive")
                            .accessibilityLabel("Encrypted drive")
                    }
                }
                Text(verbatim: "\(connection.provider.title) · \(storageName)").foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    StatusIndicator(indicator: model.indicator(connection))
                    Text(model.statusText(connection)).foregroundStyle(.secondary)
                }
                .font(.callout)
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
        DetailColumns {
            detail("Mount point") { Text(tildePath(model.mountLocation(connection))) }
            detail("Cache") {
                if let status {
                    Text("\(status.bytesCached, format: .size) of \(connection.cacheLimit, format: .size)").monospacedDigit()
                } else {
                    Text("Up to \(connection.cacheLimit, format: .size)")
                }
            }
            detail("Read-only") { connection.readOnly ? Text("On") : Text("Off") }
            switch connection.backend {
            case .gcs:
                bucketDetail
            case .s3Compatible:
                bucketDetail
                detail("Endpoint") { copyable(connection.endpoint) }
                detail("Region") { connection.region.isEmpty ? Text("Default") : Text(connection.region) }
                if connection.provider == .aws { awsDetails }
            case .sftp:
                sftpDetails
            }
        }
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
        detail("Folder") { sftp.remotePath.isEmpty ? Text("Home folder") : Text(verbatim: sftp.remotePath) }
        detail("Sign in with") { Text(sftp.authentication.title) }
    }

    @ViewBuilder private var awsDetails: some View {
        let aws = connection.aws
        detail("Storage class") { Text(aws.storageClass.title) }
        detail("Server-side encryption") {
            if aws.serverSideEncryption == .kms, !aws.kmsKeyID.isEmpty {
                copyable(aws.kmsKeyID)
            } else {
                aws.serverSideEncryption.map { Text($0.title) } ?? Text("Bucket default")
            }
        }
    }

    private func detail(_ label: LocalizedStringKey, @ViewBuilder value: () -> some View) -> some View {
        LabeledContent {
            value()
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        } label: {
            Text(label).foregroundStyle(.secondary)
        }
    }

    private func copyable(_ value: String) -> some View {
        HStack(spacing: 6) {
            Text(verbatim: value).help(value)
            CopyButton(value: value)
        }
    }

    private func problemNotice(_ problem: String) -> some View {
        DetailSection {
            Label("Connection needs attention", systemImage: "exclamationmark.triangle")
                .font(.headline)
            Text(problem).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
            Button("Check Again") { Task { await model.checkAgain(connection) } }
        }
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

private extension FormatStyle where Self == ByteCountFormatStyle {
    static var size: Self { .byteCount(style: .file, spellsOutZero: false) }
}

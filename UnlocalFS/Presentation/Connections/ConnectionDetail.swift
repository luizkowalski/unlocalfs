import AppKit
import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ConnectionDetail: View {
    @Environment(AppViewModel.self) private var model
    @AppStorage("showsDriveInfo") private var showsInfo = false
    let connection: Connection

    var body: some View {
        let status = model.servingStatus(connection)
        VStack(alignment: .leading, spacing: 20) {
            header
            notices
            if status != nil {
                ActivityView(connection: connection)
            } else if model.isDisconnected(connection) {
                disconnected
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .inspector(isPresented: $showsInfo) {
            info(status).inspectorColumnWidth(min: 220, ideal: 260, max: 360)
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
                if connection.backend.supportsUploadCleanup {
                    Button("Clean Up Unfinished Uploads…") { Task { await model.reviewUnfinishedUploads(connection) } }
                        .disabled(!model.canCleanUpUploads(connection))
                }
                Button("Show Log") { model.openLog(connection) }
                Divider()
                Button("Delete…", role: .destructive) { model.deleting = connection }
                    .disabled(!model.canEdit(connection))
            }
            .menuIndicator(.hidden)
            .help("More")
        }
        ToolbarItem {
            Button(showsInfo ? "Hide Info" : "Show Info", systemImage: "sidebar.trailing") { showsInfo.toggle() }
                .help(showsInfo ? "Hide Info" : "Show Info")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            logo
                .frame(width: 34, height: 34)
                .foregroundStyle(.tint)
                .frame(width: 56, height: 56)
                .background(.fill.quaternary, in: .rect(cornerRadius: 12))
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

    private var disconnected: some View {
        let opacity             = 0.40
        let allowsHitTesting    = false
        let accessibilityHidden = true

        return ZStack {
            DisconnectedActivityPlaceholder(connection: connection)
                .blur(radius: 2)
                .opacity(opacity)
                .allowsHitTesting(allowsHitTesting)
                .accessibilityHidden(accessibilityHidden)
            ContentUnavailableView {
                Label {
                    Text("\(connection.name) is disconnected")
                } icon: {
                    logo.frame(width: 48, height: 48)
                }
            } description: {
                Text("Connect to open it in Finder and see its transfers.")
            } actions: {
                Button("Connect") { Task { await model.toggle(connection, opensFinder: true) } }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canConnect(connection))
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private var logo: some View {
        if connection.provider == .other {
            connection.provider.logo.font(.system(size: 30, weight: .light))
        } else {
            connection.provider.logo.resizable().scaledToFit()
        }
    }

    private func info(_ status: MountStatus?) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                infoSection("Drive")
                detail("Mount point") { Text(tildePath(model.mountLocation(connection))) }
                Divider()
                detail("Read-only") { connection.readOnly ? Text("On") : Text("Off") }
                Divider()
                if let status {
                    detail("Cache") { cacheUse(status) }
                } else {
                    detail("Cache limit") { Text(connection.cacheLimit, format: .size) }
                }
                Divider()
                detail("Keep free") {
                    connection.minimumFreeSpace > 0
                        ? Text(connection.minimumFreeSpace, format: .size)
                        : Text("Not set")
                }
                infoSection("Storage")
                switch connection.backend {
                case .gcs:
                    bucketDetail
                case .s3Compatible:
                    bucketDetail
                    Divider()
                    detail("Endpoint") { copyable(connection.endpoint) }
                    Divider()
                    detail("Region") { connection.region.isEmpty ? Text("Default") : Text(connection.region) }
                    if connection.provider == .aws { awsDetails }
                case .sftp:
                    sftpDetails
                }
                Divider()
                detail("Encryption") { connection.encrypted ? Text("On") : Text("Off") }
            }
            .padding(16)
        }
    }

    private func infoSection(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 12)
            .padding(.bottom, 2)
    }

    private func cacheUse(_ status: MountStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: Double(min(status.bytesCached, connection.cacheLimit)), total: Double(connection.cacheLimit))
            Text("\(status.bytesCached, format: .size) of \(connection.cacheLimit, format: .size)").monospacedDigit()
        }
        .help("When the cache is full, the oldest copies are cleared.")
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

    @ViewBuilder private var awsDetails: some View {
        let aws = connection.aws
        Divider()
        detail("Storage class") { Text(aws.storageClass.title) }
        Divider()
        detail("Server-side encryption") {
            if aws.serverSideEncryption == .kms, !aws.kmsKeyID.isEmpty {
                copyable(aws.kmsKeyID)
            } else {
                aws.serverSideEncryption.map { Text($0.title) } ?? Text("Bucket default")
            }
        }
    }

    private func detail(_ label: LocalizedStringKey, @ViewBuilder value: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            value()
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func copyable(_ value: String) -> some View {
        HStack(spacing: 6) {
            Text(verbatim: value).help(value)
            CopyButton(value: value)
        }
    }

    @ViewBuilder private var notices: some View {
        let problem = model.problem(connection)
        let failure = model.uploadFailure(connection)
        let isOffline = model.isOffline(connection)
        if problem != nil || failure != nil || isOffline {
            FittedScrollView {
                if let problem {
                    problemNotice(problem)
                }
                if let failure {
                    uploadFailureNotice(failure.uploadError)
                }
                if isOffline {
                    Label("Network unavailable. Cached files are kept.", systemImage: "wifi.slash")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func problemNotice(_ problem: String) -> some View {
        notice("Connection needs attention") {
            Text(problem).textSelection(.enabled)
        } actions: {
            Button("Check Again") { Task { await model.checkAgain(connection) } }
        }
    }

    private func uploadFailureNotice(_ error: String?) -> some View {
        notice("Uploads are failing") {
            if let error {
                Text(error).textSelection(.enabled)
            } else {
                Text("rclone did not report a reason. The log has the details.")
            }
            Text("UnlocalFS tries again on its own, up to every 5 minutes, while the drive stays connected.")
        } actions: {
            if error == nil {
                Button("Show Log") { model.openLog(connection) }
            }
        }
    }

    private func notice(
        _ title: LocalizedStringKey, @ViewBuilder message: () -> some View, @ViewBuilder actions: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Label(title, systemImage: "exclamationmark.triangle")
                .font(.headline)
            VStack(alignment: .leading, spacing: 12) { message() }.font(.callout).foregroundStyle(.secondary)
            actions()
            Divider()
        }
    }

    private func tildePath(_ url: URL) -> String {
        (url.path(percentEncoded: false) as NSString).abbreviatingWithTildeInPath
    }
}

private struct FittedScrollView<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var height: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: height)
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

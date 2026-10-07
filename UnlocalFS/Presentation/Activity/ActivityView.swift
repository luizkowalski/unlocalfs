import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ActivityView: View {
    let connection: Connection
    let notice: String?
    @Environment(ViewModelFactory.self) private var viewModels
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: ActivityViewModel?

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                switch viewModel?.activity {
                case nil:
                    ProgressView("Checking activity…").controlSize(.small)
                case .failure(let error):
                    status("exclamationmark.triangle", tint: .orange, title: Text("Activity unavailable")) {
                        Text(error.localizedDescription).textSelection(.enabled)
                    }
                case .success:
                    if let summary = viewModel?.summary {
                        transfers(summary)
                    } else {
                        status("checkmark", tint: .green, title: idleTitle) {
                            Text("Files show up here while they upload or download.")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .task(id: connection.id) {
            let viewModel = self.viewModel ?? viewModels.makeActivity()
            self.viewModel = viewModel
            await viewModel.observe(connection)
        }
    }

    private var idleTitle: Text {
        connection.readOnly ? Text("No transfers in progress") : Text("All changes are uploaded")
    }

    private func transfers(_ summary: TransferSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let title = summary.isUploading
                ? Text("Uploading ^[\(summary.fileCount) file](inflect: true)")
                : Text("Downloading ^[\(summary.fileCount) file](inflect: true)")
            HStack {
                status(summary.isUploading ? "arrow.up" : "arrow.down", tint: .accentColor, title: title) {
                    if summary.isUploading, let notice { Text(notice) }
                }
                .symbolEffect(summary.isUploading ? .wiggle.up : .wiggle.down, options: .repeat(.periodic(delay: 1.5)), isActive: !reduceMotion)
                .symbolEffect(.pulse, isActive: reduceMotion)
                Spacer()
                if summary.bytesTotal > 0 {
                    Text("\(summary.bytesLeft, format: .byteCount(style: .file)) left")
                        .font(.title3.weight(.medium)).monospacedDigit()
                }
            }
            if summary.bytesTotal > 0 {
                ProgressView(value: Double(summary.bytesDone), total: Double(summary.bytesTotal))
                    .accessibilityLabel(title)
                    .padding(.top, 16)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(summary.files) {
                    Divider()
                    ActivityRow(activity: $0).padding(.vertical, 10)
                }
                if summary.hiddenFileCount > 0 {
                    Divider()
                    Text("^[\(summary.hiddenFileCount) more file](inflect: true)")
                        .foregroundStyle(.secondary)
                        .padding(.leading, 30)
                        .padding(.top, 10)
                }
            }
            .padding(.top, 14)
        }
    }

    private func status(_ symbol: String, tint: Color, title: Text, @ViewBuilder detail: () -> some View) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.15), in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                title.font(.title3.weight(.semibold))
                detail().foregroundStyle(.secondary)
            }
        }
    }
}

private struct ActivityRow: View {
    let activity: FileActivity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(tint).frame(width: 18)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name).lineLimit(1).truncationMode(.middle).textSelection(.enabled)
                            .help(activity.path)
                        Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                    }
                    Spacer()
                    Group {
                        if let progress {
                            Text("\(progress, format: .byteCount(style: .file)) of \(activity.size, format: .byteCount(style: .file))")
                        } else if activity.size >= 0 {
                            Text(activity.size, format: .byteCount(style: .file))
                        }
                    }
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
                if let progress {
                    ProgressView(value: Double(progress), total: Double(activity.size))
                        .accessibilityLabel("\(stateText): \(activity.path)")
                }
            }
        }
    }

    private var progress: Int64? {
        activity.size > 0 ? activity.bytesTransferred : nil
    }

    private var name: String { (activity.path as NSString).lastPathComponent }

    private var detail: String {
        let folder = (activity.path as NSString).deletingLastPathComponent
        return folder.isEmpty ? stateText : "\(stateText) · \(folder)"
    }

    private var stateText: String {
        switch activity.state {
        case .queued: String(localized: "Queued for upload")
        case .uploading: String(localized: "Uploading")
        case .retrying: String(localized: "Waiting to retry upload")
        case .downloading: String(localized: "Downloading")
        }
    }

    private var symbol: String {
        switch activity.state {
        case .queued: "clock"
        case .uploading: "arrow.up.circle"
        case .retrying: "arrow.clockwise.circle"
        case .downloading: "arrow.down.circle"
        }
    }

    private var tint: Color {
        switch activity.state {
        case .queued: .secondary
        case .uploading, .downloading: .accentColor
        case .retrying: .orange
        }
    }
}

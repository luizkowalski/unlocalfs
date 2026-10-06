import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ActivityView: View {
    let connection: Connection
    @Environment(ViewModelFactory.self) private var viewModels
    @State private var viewModel: ActivityViewModel?

    var body: some View {
        GroupBox("Activity") {
            VStack(alignment: .leading, spacing: 14) {
                switch viewModel?.activity {
                case nil:
                    ProgressView("Checking activity…").controlSize(.small)
                case .failure(let error):
                    Label("Activity unavailable", systemImage: "exclamationmark.triangle")
                    Text(error.localizedDescription).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                case .success(let activity) where activity.isEmpty:
                    Text("No transfers in progress").foregroundStyle(.secondary)
                case .success(let activity):
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(activity) { ActivityRow(activity: $0) }
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
}

private struct ActivityRow: View {
    let activity: FileActivity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(.secondary).frame(width: 18)
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.path).lineLimit(2).truncationMode(.middle).textSelection(.enabled)
                    .help(activity.path)
                HStack {
                    Text(stateText)
                    Spacer()
                    if let progress {
                        Text("\(progress, format: .byteCount(style: .file)) of \(activity.size, format: .byteCount(style: .file))")
                    } else if activity.size >= 0 {
                        Text(activity.size, format: .byteCount(style: .file))
                    }
                }
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()
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
}

import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ActivityView: View {
    let connection: Connection
    @Environment(AppViewModel.self) private var model
    @Environment(ViewModelFactory.self) private var viewModels
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: ActivityViewModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            activity
            if let speeds = model.speeds[connection.id] {
                SpeedChart(speeds: speeds)
            }
        }
        .task(id: connection.id) {
            let viewModel = viewModel ?? viewModels.makeActivity()
            self.viewModel = viewModel
            await viewModel.observe(connection)
        }
        .confirmationDialog(
            viewModel?.cancellation?.title ?? "",
            item: Binding(get: { viewModel?.cancellation }, set: { viewModel?.cancellation = $0 }),
            titleVisibility: .visible,
        ) { cancellation in
            Button("Delete File", role: .destructive) { Task { await viewModel?.stopUpload(cancellation) } }
        } message: { cancellation in
            Text(cancellation.message)
        }
        .alert("UnlocalFS", item: Binding(get: { viewModel?.alert }, set: { viewModel?.alert = $0 })) { _ in
        } message: {
            Text($0)
        }
    }

    private func askToStop(_ activity: FileActivity) {
        viewModel?.prepareCancellation(of: activity, in: connection)
    }

    private var activity: some View {
        let summary = viewModel?.summary
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Activity").font(.headline)
                Spacer()
                if let summary, summary.fileCount > 0 {
                    transfers(summary).foregroundStyle(.secondary)
                }
            }
            if case let .failure(error) = viewModel?.activity {
                Text(error.localizedDescription).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
            }
            ActivityTable(files: summary?.files ?? [], cancel: askToStop) {
                switch viewModel?.activity {
                case .success:
                    idle
                case nil:
                    Text("Checking activity…").foregroundStyle(.secondary)
                case .failure:
                    Label("Activity unavailable", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                }
            }
        }
    }

    private var idle: some View {
        let titleText: LocalizedStringKey = connection.readOnly ? "No transfers in progress" : "All changes are uploaded"
        return HStack(spacing: 6) {
            Image(systemName: "checkmark.rectangle.stack.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 23, height: 23)
                .accessibilityHidden(true)
            Text(titleText).font(.title3)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func transfers(_ summary: TransferSummary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: summary.isUploading ? "arrow.up" : "arrow.down")
                .foregroundStyle(.tint)
                .symbolEffect(summary.isUploading ? .wiggle.up : .wiggle.down, options: .repeat(.periodic(delay: 1.5)), isActive: !reduceMotion)
                .symbolEffect(.pulse, isActive: reduceMotion)
                .accessibilityHidden(true)
            if summary.isUploading {
                Text("Uploading ^[\(summary.fileCount) file](inflect: true)")
            } else {
                Text("Downloading ^[\(summary.fileCount) file](inflect: true)")
            }
        }
    }
}

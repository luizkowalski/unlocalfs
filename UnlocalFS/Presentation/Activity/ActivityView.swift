import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ActivityView: View {
    let connection: Connection
    @Environment(ViewModelFactory.self) private var viewModels
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: ActivityViewModel?

    var body: some View {
        let summary = viewModel?.summary
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Activity").font(.headline)
                Spacer()
                headline(summary).foregroundStyle(.secondary)
            }
            if case .failure(let error) = viewModel?.activity {
                Text(error.localizedDescription).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
            }
            if case .success = viewModel?.activity {
                ActivityTable(files: summary?.files ?? []) { idle }
            }
            if let summary, summary.hiddenFileCount > 0 {
                Text("^[\(summary.hiddenFileCount) more file](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
        }
        .task(id: connection.id) {
            let viewModel = self.viewModel ?? viewModels.makeActivity()
            self.viewModel = viewModel
            await viewModel.observe(connection)
        }
    }

    @ViewBuilder private func headline(_ summary: TransferSummary?) -> some View {
        switch viewModel?.activity {
        case nil:
            Text("Checking activity…")
        case .failure:
            Label("Activity unavailable", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
        case .success:
            if let summary, summary.fileCount > 0 {
                transfers(summary)
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
            if let bytesPerSecond = summary.bytesPerSecond {
                Text(verbatim: "·")
                Text("\(bytesPerSecond, format: .byteCount(style: .file))/s")
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .default, value: bytesPerSecond)
            }
        }
    }
}

import AppKit
import SwiftUI
import UniformTypeIdentifiers
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
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            if connection.readOnly {
                Text("No transfers in progress")
            } else {
                Text("All changes are uploaded")
            }
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
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

private struct ActivityTable<Empty: View>: View {
    let files: [FileActivity]
    @ViewBuilder let empty: Empty
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ActivityTableRow {
                Text("Name")
            } folder: {
                Text("Folder")
            } status: {
                Text("Status")
            } size: {
                Text("Size")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            Divider()
            if files.isEmpty {
                empty
            }
            ForEach(Array(files.enumerated()), id: \.element.id) { index, activity in
                ActivityRow(activity: activity)
                    .background(Color(nsColor: .alternatingContentBackgroundColors[index.isMultiple(of: 2) ? 0 : 1]))
            }
        }
        .animation(reduceMotion ? nil : .default, value: files.map(\.id))
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator) }
    }
}

private struct ActivityTableRow<Name: View, Folder: View, Status: View, Size: View>: View {
    @ViewBuilder let name: Name
    @ViewBuilder let folder: Folder
    @ViewBuilder let status: Status
    @ViewBuilder let size: Size

    var body: some View {
        HStack(spacing: 12) {
            name.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            folder.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            status.frame(width: 150, alignment: .leading)
            size.frame(width: 74, alignment: .trailing)
        }
        .lineLimit(1)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

private struct ActivityRow: View {
    let activity: FileActivity
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingFailure = false

    var body: some View {
        ActivityTableRow {
            HStack(spacing: 7) {
                Image(nsImage: NSWorkspace.shared.icon(for: UTType(filenameExtension: (name as NSString).pathExtension) ?? .data))
                    .resizable()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
                Text(name).truncationMode(.middle).textSelection(.enabled)
            }
            .help(activity.path)
        } folder: {
            Text(folder).truncationMode(.middle).foregroundStyle(.secondary).help(folder)
        } status: {
            statusView.font(.caption).foregroundStyle(.secondary)
                .popover(isPresented: $showingFailure, arrowEdge: .bottom) { failureDetails }
        } size: {
            if activity.size >= 0 {
                Text(activity.size, format: .byteCount(style: .file))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder private var statusView: some View {
        switch activity.state {
        case .queued:
            Text("Waiting")
        case .failed:
            Button { showingFailure = true } label: {
                HStack(spacing: 4) {
                    Label("Upload failed", systemImage: "exclamationmark.triangle.fill")
                    Image(systemName: "info.circle").accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.orange)
            .accessibilityLabel("Upload failed, show details")
            .help("Show why the upload failed")
        case .uploaded:
            finished(Text("Uploaded"))
        case .downloaded:
            finished(Text("Downloaded"))
        case .uploading, .downloading:
            HStack(spacing: 6) {
                if activity.uploadError != nil {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Trying again after a failed upload")
                        .help("Trying again after a failed upload")
                }
                progress
            }
        }
    }

    @ViewBuilder private var progress: some View {
        if activity.size > 0, let transferred = activity.bytesTransferred {
            let fraction = min(Double(transferred) / Double(activity.size), 1)
            HStack(spacing: 6) {
                ProgressView(value: fraction)
                    .controlSize(.small)
                    .accessibilityLabel(movingText)
                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .frame(width: 34, alignment: .leading)
            }
            .animation(reduceMotion ? nil : .linear(duration: 0.25), value: fraction)
            .help(movingText)
        } else {
            movingText
        }
    }

    private var failureDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name).font(.headline)
            if let error = activity.uploadError {
                Text(error).textSelection(.enabled)
            } else {
                Text("rclone did not report a reason.")
            }
            nextAttempt.foregroundStyle(.secondary)
        }
        .font(.callout)
        .fixedSize(horizontal: false, vertical: true)
        .padding(14)
        .frame(width: 320, alignment: .leading)
    }

    @ViewBuilder private var nextAttempt: some View {
        switch activity.state {
        case .failed(let date) where date > .now:
            Text("Retry \(date, format: .relative(presentation: .named))")
        case .failed:
            Text("Retrying soon")
        default:
            Text("Uploading again")
        }
    }

    private func finished(_ title: Text) -> some View {
        Label {
            title
        } icon: {
            Image(systemName: "checkmark").foregroundStyle(.green)
        }
    }

    private var movingText: Text {
        activity.state == .downloading ? Text("Downloading") : Text("Uploading")
    }

    private var name: String { (activity.path as NSString).lastPathComponent }

    private var folder: String { (activity.path as NSString).deletingLastPathComponent }
}

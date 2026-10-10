import AppKit
import SwiftUI
import UniformTypeIdentifiers
import UnlocalFSDomain
import UnlocalFSPresentation

struct ActivitySection: View {
    let viewModel: ActivityViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if case .failure(let error) = viewModel.activity {
            DetailSection {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Activity unavailable")
                        Text(error.localizedDescription).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                } icon: {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
                }
            }
        } else if let summary = viewModel.summary {
            transfers(summary)
        }
    }

    private func transfers(_ summary: TransferSummary) -> some View {
        DetailSection(
            title: summary.isUploading ? Text("Uploads") : Text("Downloads"),
            footer: summary.finderFileCount > 0 ? Text("Finder metadata files, such as .DS_Store, are not listed.") : nil
        ) {
            LabeledContent {
                if let bytesPerSecond = summary.bytesPerSecond {
                    speed(bytesPerSecond, timeLeft: summary.timeLeft).foregroundStyle(.secondary)
                }
            } label: {
                if summary.isUploading, summary.bytesTotal > 0 {
                    Text("^[\(summary.fileCount) file](inflect: true) left · \(summary.bytesLeft, format: .byteCount(style: .file))")
                } else if summary.isUploading {
                    Text("Uploading ^[\(summary.fileCount) file](inflect: true)")
                } else {
                    Text("Downloading ^[\(summary.fileCount) file](inflect: true)")
                }
            }
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : .default, value: summary.bytesLeft)
            ForEach(summary.files) { ActivityRow(activity: $0) }
            if summary.hiddenFileCount > 0 {
                Text("^[\(summary.hiddenFileCount) more file](inflect: true)").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private func speed(_ bytesPerSecond: Int64, timeLeft: Duration?) -> some View {
        let speed = bytesPerSecond.formatted(.byteCount(style: .file))
        if let timeLeft {
            let duration = timeLeft.formatted(.units(allowed: [.hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 1))
            Text("\(speed)/s · about \(duration) left")
        } else {
            Text("\(speed)/s")
        }
    }
}

private struct ActivityRow: View {
    let activity: FileActivity

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(for: UTType(filenameExtension: (name as NSString).pathExtension) ?? .data))
                .resizable()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).lineLimit(1).truncationMode(.middle).textSelection(.enabled)
                    .help(activity.path)
                if !folder.isEmpty {
                    Text(folder).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }
            }
            Spacer(minLength: 12)
            trailing.font(.caption)
        }
    }

    @ViewBuilder private var trailing: some View {
        switch activity.state {
        case .queued:
            Text("Waiting").foregroundStyle(.secondary)
            Image(systemName: "clock").foregroundStyle(.secondary).accessibilityHidden(true)
        case .retrying:
            Text("Waiting to retry upload").foregroundStyle(.orange)
            Image(systemName: "arrow.clockwise").foregroundStyle(.orange).accessibilityHidden(true)
        case .uploading, .downloading:
            if let progress, progress < activity.size {
                Text("\(progress, format: .byteCount(style: .file)) of \(activity.size, format: .byteCount(style: .file))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                ProgressView(value: Double(progress), total: Double(activity.size))
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                    .accessibilityLabel(activity.state == .uploading ? Text("Uploading") : Text("Downloading"))
            } else {
                if progress != nil {
                    Text("Finishing").foregroundStyle(.secondary)
                }
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(activity.state == .uploading ? Text("Uploading") : Text("Downloading"))
            }
        }
    }

    private var progress: Int64? {
        activity.size > 0 ? activity.bytesTransferred : nil
    }

    private var name: String { (activity.path as NSString).lastPathComponent }

    private var folder: String { (activity.path as NSString).deletingLastPathComponent }
}

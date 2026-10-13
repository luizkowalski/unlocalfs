import SwiftUI
import UnlocalFSDomain

struct ActivityStatus: View {
    let activity: FileActivity
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch activity.state {
        case .queued:
            Text("Waiting")
        case .failed(let nextAttempt):
            FailedUploadButton(name: name, error: activity.uploadError, nextAttempt: nextAttempt)
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
}

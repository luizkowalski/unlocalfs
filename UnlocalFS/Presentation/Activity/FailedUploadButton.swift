import SwiftUI

struct FailedUploadButton: View {
    let name: String
    let error: String?
    let nextAttempt: Date
    @State private var showingDetails = false

    var body: some View {
        Button { showingDetails = true } label: {
            HStack(spacing: 4) {
                Label("Upload failed", systemImage: "exclamationmark.triangle.fill")
                Image(systemName: "info.circle").accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.orange)
        .accessibilityLabel("Upload failed, show details")
        .help("Show why the upload failed")
        .popover(isPresented: $showingDetails, arrowEdge: .bottom) { details }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name).font(.headline)
            if let error {
                Text(error).textSelection(.enabled)
            } else {
                Text("The reason is not available. The log has the details.")
            }
            Group {
                if nextAttempt > .now {
                    Text("Retry \(nextAttempt, format: .relative(presentation: .named))")
                } else {
                    Text("Retrying soon")
                }
            }
            .foregroundStyle(.secondary)
        }
        .font(.callout)
        .foregroundStyle(.primary)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .padding(14)
        .frame(width: 320, alignment: .leading)
    }
}

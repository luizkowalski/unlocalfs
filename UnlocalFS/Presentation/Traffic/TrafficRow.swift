import SwiftUI
import UnlocalFSPresentation

struct TrafficRow: View {
    let viewModel: TrafficViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Traffic")
                Text("\(viewModel.recentTotal.total, format: .size), last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.vertical, 4)
        }
    }
}

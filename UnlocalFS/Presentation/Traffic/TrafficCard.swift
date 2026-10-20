import Charts
import SwiftUI
import UnlocalFSPresentation

struct TrafficCard: View {
    let viewModel: TrafficViewModel
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Traffic, last 30 days").font(.caption)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption2.bold())
                }
                .foregroundStyle(isSelected ? AnyShapeStyle(.white.opacity(0.8)) : AnyShapeStyle(.secondary))
                Text(viewModel.recentTotal.total, format: .size).font(.title3.weight(.semibold)).monospacedDigit()
                Chart(viewModel.recent) { bar in
                    BarMark(x: .value("Date", bar.interval.start, unit: .day), y: .value("Total", bar.traffic.total))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.accentColor.opacity(0.7))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 22)
                .accessibilityHidden(true)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(10)
            .background(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.fill.quaternary), in: .rect(cornerRadius: 8))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

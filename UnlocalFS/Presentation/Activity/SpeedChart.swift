import Charts
import SwiftUI
import UnlocalFSPresentation

struct SpeedChart: View {
    let speeds: [SpeedSample]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedDate: Date?

    var body: some View {
        let end = speeds.last?.date ?? .now
        let shown = selectedSample ?? speeds.last
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text("Speed").font(.headline)
                Spacer()
                if let shown, shown != speeds.last {
                    Text(shown.date, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                rate(shown?.upload ?? 0, direction: .upload)
                rate(shown?.download ?? 0, direction: .download)
            }
            chart(end: end)
                .frame(height: 140)
                .padding(14)
                .background(.fill.quinary, in: .rect(cornerRadius: 10))
                .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator) }
        }
    }

    private var selectedSample: SpeedSample? {
        guard let selectedDate else { return nil }
        return speeds.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }

    private func chart(end: Date) -> some View {
        let start = end.addingTimeInterval(-AppViewModel.speedWindow)
        let peak = max(speeds.map { max($0.upload, $0.download) }.max() ?? 0, 1_000_000) * 1.1
        return Chart {
            ForEach(speeds, id: \.date) { sample in
                plot(sample.date, sample.upload, direction: .upload)
                plot(sample.date, -sample.download, direction: .download)
            }
            if let selected = selectedSample {
                RuleMark(x: .value("Time", selected.date))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                PointMark(x: .value("Time", selected.date), y: .value("Speed", selected.upload))
                    .foregroundStyle(Direction.upload.color)
                    .symbolSize(30)
                PointMark(x: .value("Time", selected.date), y: .value("Speed", -selected.download))
                    .foregroundStyle(Direction.download.color)
                    .symbolSize(30)
            }
        }
        .chartForegroundStyleScale { (direction: Direction) in direction.fill }
        .chartLegend(.hidden)
        .chartXScale(domain: start...end)
        .chartYScale(domain: -peak...peak)
        .chartXSelection(value: $selectedDate)
        .chartXAxis {
            AxisMarks(values: stride(from: 0, through: AppViewModel.speedWindow, by: 15).map { start.addingTimeInterval($0) }) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3])).foregroundStyle(.quaternary)
                if value.index == 0 {
                    AxisValueLabel("1 min ago", anchor: .topLeading)
                } else if value.index == value.count - 1 {
                    AxisValueLabel("Now", anchor: .topTrailing)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                let speed = value.as(Double.self) ?? 0
                if speed == 0 {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(.tertiary)
                } else {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3])).foregroundStyle(.quaternary)
                    AxisValueLabel { speedText(abs(speed)) }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Speed in the last minute")
        .accessibilityValue(Text(
            "Fastest upload \(byteCount(speeds.map(\.upload).max() ?? 0))/s, fastest download \(byteCount(speeds.map(\.download).max() ?? 0))/s"
        ))
    }

    @ChartContentBuilder private func plot(_ date: Date, _ speed: Double, direction: Direction) -> some ChartContent {
        AreaMark(x: .value("Time", date), y: .value("Speed", speed), stacking: .unstacked)
            .foregroundStyle(by: .value("Direction", direction))
            .alignsMarkStylesWithPlotArea()
            .interpolationMethod(.monotone)
        LineMark(x: .value("Time", date), y: .value("Speed", speed), series: .value("Direction", direction))
            .foregroundStyle(direction.color)
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 1.5, lineJoin: .round))
    }

    private func rate(_ speed: Double, direction: Direction) -> some View {
        HStack(spacing: 4) {
            Image(systemName: direction.symbol)
                .foregroundStyle(direction.color)
                .accessibilityLabel(direction.label)
            speedText(speed)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .default, value: speed)
        }
        .accessibilityElement(children: .combine)
    }

    private func speedText(_ speed: Double) -> Text {
        Text("\(byteCount(speed))/s")
    }

    private func byteCount(_ speed: Double) -> String {
        Int64(speed.rounded()).formatted(.byteCount(style: .file, spellsOutZero: false))
    }
}

private enum Direction: String, Plottable {
    case upload, download

    var color: Color { self == .upload ? .accentColor : .teal }
    var symbol: String { self == .upload ? "arrow.up" : "arrow.down" }
    var label: LocalizedStringKey { self == .upload ? "Upload speed" : "Download speed" }

    var fill: LinearGradient {
        let strong = color.opacity(0.45)
        let faint = color.opacity(0.08)
        let stops: [Gradient.Stop] = self == .upload
            ? [.init(color: strong, location: 0), .init(color: faint, location: 0.5)]
            : [.init(color: faint, location: 0.5), .init(color: strong, location: 1)]
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }
}

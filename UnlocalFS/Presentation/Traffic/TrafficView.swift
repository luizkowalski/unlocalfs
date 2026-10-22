import Charts
import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct TrafficView: View {
    @Bindable var viewModel: TrafficViewModel
    @State private var isPickingRange = false
    @State private var dragged: ClosedRange<Date>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 16) {
                        heading
                        Spacer(minLength: 0)
                        periodPicker
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        heading
                        periodPicker
                    }
                }
                if let error = viewModel.error {
                    Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary).textSelection(.enabled)
                } else if let total = viewModel.total {
                    TrafficStats(traffic: total)
                    TrafficChart(viewModel: viewModel, dragged: $dragged)
                    TrafficList(rows: viewModel.rows, quiet: viewModel.quiet)
                }
            }
            .padding(28)
        }
        .navigationTitle("Traffic")
        .onChange(of: dragged) {
            if let dragged { viewModel.pick(dragged) }
        }
        .onChange(of: viewModel.period) {
            if viewModel.period == .custom { isPickingRange = true }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                title.font(.title.weight(.semibold))
                if viewModel.picked != nil {
                    Button("Show Whole Period", systemImage: "xmark.circle.fill", action: viewModel.showAll)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Show Whole Period")
                }
            }
            Text(viewModel.picked == nil ? "Drag across the chart to pick days" : "Picked on the chart").foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .fixedSize()
    }

    @ViewBuilder private var title: some View {
        if let picked = viewModel.picked {
            Text(picked.formattedDays)
        } else {
            switch viewModel.period {
            case .last30Days: Text("Last 30 Days")
            case .last90Days: Text("Last 90 Days")
            case .last12Months: Text("Last 12 Months")
            case .custom:
                Button { isPickingRange = true } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.interval.formattedDays)
                        Image(systemName: "chevron.down").font(.callout.bold()).foregroundStyle(.secondary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help("Change Dates")
            }
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.period) {
            Text("30 Days").tag(TrafficPeriod.last30Days)
            Text("90 Days").tag(TrafficPeriod.last90Days)
            Text("12 Months").tag(TrafficPeriod.last12Months)
            Text("Custom").tag(TrafficPeriod.custom)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .popover(isPresented: $isPickingRange, arrowEdge: .bottom) { TrafficRangePicker(range: $viewModel.custom) }
    }
}

private struct TrafficStats: View {
    let traffic: Traffic

    var body: some View {
        HStack(alignment: .bottom, spacing: 40) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total").font(.subheadline).foregroundStyle(.secondary)
                Text(traffic.total, format: .size).font(.system(size: 30, weight: .semibold))
            }
            stat("Upload", .upload, traffic.upload)
            stat("Download", .download, traffic.download)
        }
        .monospacedDigit()
        .lineLimit(1)
    }

    private func stat(_ title: LocalizedStringKey, _ direction: Direction, _ bytes: Int64) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label { Text(title) } icon: { Image(systemName: direction.symbol).foregroundStyle(direction.color).fontWeight(.semibold) }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(bytes, format: .size).font(.system(size: 22, weight: .semibold)).foregroundStyle(.secondary)
        }
    }
}

private struct TrafficChart: View {
    let viewModel: TrafficViewModel
    @Binding var dragged: ClosedRange<Date>?

    var body: some View {
        Chart {
            if let picked = viewModel.picked {
                RectangleMark(xStart: .value("Date", picked.start), xEnd: .value("Date", picked.end))
                    .foregroundStyle(Color.accentColor.opacity(0.1))
            }
            ForEach(viewModel.bars) { bar in
                let opacity = viewModel.highlights(bar) ? 1 : 0.3
                BarMark(x: .value("Date", bar.interval.start, unit: viewModel.unit), y: .value("Upload", bar.traffic.upload))
                    .foregroundStyle(Direction.upload.color.opacity(opacity))
                BarMark(x: .value("Date", bar.interval.start, unit: viewModel.unit), y: .value("Download", bar.traffic.download))
                    .foregroundStyle(Direction.download.color.opacity(opacity))
            }
        }
        .chartXSelection(range: $dragged)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 3])).foregroundStyle(.tertiary)
                AxisValueLabel {
                    let bytes = Int64(value.as(Double.self) ?? 0)
                    if bytes == 0 { Text(0, format: .number) } else { Text(bytes, format: .size) }
                }
            }
        }
        .frame(height: 170)
    }
}

private struct TrafficList: View {
    let rows: [DriveTraffic]
    let quiet: [String]

    var body: some View {
        let peak = max(rows.first?.traffic.total ?? 1, 1)
        VStack(alignment: .leading, spacing: 10) {
            if rows.isEmpty {
                Text("No drive moved data in this period.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(.fill.quinary, in: .rect(cornerRadius: 10))
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 9) {
                    GridRow {
                        Text("Drive")
                        Color.clear.frame(height: 1)
                        Text("Upload").gridColumnAlignment(.trailing)
                        Text("Download").gridColumnAlignment(.trailing)
                        Text("Total").gridColumnAlignment(.trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    ForEach(rows) { row in
                        Divider()
                        GridRow {
                            Label { Text(row.name) } icon: { ProviderIcon(provider: row.provider, size: 16).foregroundStyle(.secondary) }
                            ShareBar(traffic: row.traffic, peak: peak).frame(minWidth: 60, maxWidth: .infinity).accessibilityHidden(true)
                            Text(row.traffic.upload, format: .size).foregroundStyle(.secondary)
                            Text(row.traffic.download, format: .size).foregroundStyle(.secondary)
                            Text(row.traffic.total, format: .size).fontWeight(.medium)
                        }
                        .monospacedDigit()
                    }
                }
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.fill.quinary, in: .rect(cornerRadius: 10))
                .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator) }
            }
            if !quiet.isEmpty {
                Text("No traffic from \(quiet.formatted(.list(type: .and))).")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 14)
            }
        }
    }
}

private struct ShareBar: View {
    let traffic: Traffic
    let peak: Int64

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * Double(traffic.total) / Double(peak)
            let uploadShare = Double(traffic.upload) / Double(max(traffic.total, 1))
            HStack(spacing: 1) {
                Direction.upload.color.frame(width: width * uploadShare)
                Direction.download.color.frame(width: width * (1 - uploadShare))
            }
            .clipShape(.capsule)
            .frame(height: 6)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 16)
    }
}

extension DateInterval {
    var formattedDays: String {
        (start..<max(start, end.addingTimeInterval(-1))).formatted(.interval.day().month(.abbreviated).year())
    }
}

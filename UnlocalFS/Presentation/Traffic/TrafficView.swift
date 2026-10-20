import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct TrafficView: View {
    @Environment(AppViewModel.self) private var model
    @Environment(ViewModelFactory.self) private var viewModels
    @State private var viewModel: TrafficViewModel?

    var body: some View {
        Group {
            if let viewModel { TrafficPage(viewModel: viewModel) }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Traffic")
        .task {
            let viewModel = viewModels.makeTraffic()
            viewModel.reload()
            self.viewModel = viewModel
        }
        .onChange(of: model.statuses.mapValues(\.unsavedTraffic)) { viewModel?.reload() }
        .onChange(of: model.connections) { viewModel?.reload() }
    }
}

private struct TrafficPage: View {
    @Bindable var viewModel: TrafficViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    summary
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 10) {
                        picker
                        if viewModel.period == .custom { dates }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    summary
                    picker
                    if viewModel.period == .custom { dates }
                }
            }
            if let error = viewModel.error {
                Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary).textSelection(.enabled)
            } else {
                TrafficTable(rows: viewModel.rows)
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("All drives").font(.headline).foregroundStyle(.secondary)
            if let total = viewModel.total {
                Text(total.total, format: .size).font(.system(size: 34, weight: .semibold)).monospacedDigit()
                HStack(spacing: 12) {
                    Label { Text("\(total.upload, format: .size) upload") } icon: { arrow(.upload) }
                    Label { Text("\(total.download, format: .size) download") } icon: { arrow(.download) }
                }
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
        }
        .lineLimit(1)
        .fixedSize()
    }

    private func arrow(_ direction: Direction) -> some View {
        Image(systemName: direction.symbol).foregroundStyle(direction.color)
    }

    private var picker: some View {
        Picker("Period", selection: $viewModel.period) {
            Text("Today").tag(TrafficPeriod.today)
            Text("This Week").tag(TrafficPeriod.week)
            Text("This Month").tag(TrafficPeriod.month)
            Text("This Year").tag(TrafficPeriod.year)
            Text("Custom").tag(TrafficPeriod.custom)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
    }

    private var dates: some View {
        HStack(spacing: 8) {
            DatePicker("From", selection: $viewModel.start, in: ...Date.now, displayedComponents: .date)
            DatePicker("To", selection: $viewModel.end, in: ...Date.now, displayedComponents: .date)
        }
        .datePickerStyle(.field)
        .fixedSize()
    }
}

private struct TrafficTable: View {
    let rows: [DriveTraffic]

    var body: some View {
        let peak = max(rows.map(\.traffic.total).max() ?? 0, 1)
        Table(rows) {
            TableColumn("Drive") { row in
                Label {
                    Text(row.name)
                } icon: {
                    ProviderIcon(provider: row.provider, size: 16)
                }
            }
            TableColumn("Total") { row in
                HStack(spacing: 8) {
                    Text(row.traffic.total, format: .size).monospacedDigit().frame(width: 74, alignment: .trailing)
                    ShareBar(traffic: row.traffic, peak: peak).accessibilityHidden(true)
                }
            }
            .width(min: 160)
            TableColumn("Upload") { row in
                Text(row.traffic.upload, format: .size).monospacedDigit().foregroundStyle(.secondary)
            }
            .width(min: 70, ideal: 90)
            TableColumn("Download") { row in
                Text(row.traffic.download, format: .size).monospacedDigit().foregroundStyle(.secondary)
            }
            .width(min: 70, ideal: 90)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: rows.count > 1))
        .lineLimit(1)
        .frame(minHeight: 120, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator) }
    }
}

private struct ShareBar: View {
    let traffic: Traffic
    let peak: Int64

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * Double(traffic.total) / Double(peak)
            let uploadShare = traffic.total > 0 ? Double(traffic.upload) / Double(traffic.total) : 0
            HStack(spacing: 0) {
                Rectangle().fill(Direction.upload.color).frame(width: width * uploadShare)
                Rectangle().fill(Direction.download.color).frame(width: width * (1 - uploadShare))
            }
            .clipShape(.rect(cornerRadius: 2))
            .frame(height: 8)
            .frame(maxHeight: .infinity)
        }
    }
}

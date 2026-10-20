import SwiftUI
import UnlocalFSPresentation

struct TrafficRangePicker: View {
    @Binding var range: ClosedRange<Date>
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ClosedRange<Date>
    @State private var pending: Date?
    @State private var month: Date

    init(range: Binding<ClosedRange<Date>>) {
        _range = range
        _draft = State(initialValue: range.wrappedValue)
        _month = State(initialValue: Calendar.current.dateInterval(of: .month, for: range.wrappedValue.upperBound)?.start ?? range.wrappedValue.upperBound)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(TrafficPreset.allCases, id: \.self) { preset in
                    let days = preset.days(now: .now, calendar: .current)
                    Button { apply(days) } label: {
                        preset.title
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(draft == days ? Color.accentColor.opacity(0.2) : .clear, in: .rect(cornerRadius: 5))
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 130)
            .padding(10)
            Divider()
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 24) {
                    MonthGrid(month: month.adding(months: -1), range: draft, tap: tap)
                    MonthGrid(month: month, range: draft, tap: tap)
                }
                .overlay(alignment: .top) {
                    HStack {
                        Button("Previous Month", systemImage: "chevron.left") { month = month.adding(months: -1) }
                        Spacer()
                        Button("Next Month", systemImage: "chevron.right") { month = month.adding(months: 1) }
                            .disabled(month.adding(months: 1) > .now)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                }
                Divider()
                HStack {
                    if pending == nil {
                        let days = Calendar.current.dateComponents([.day], from: draft.lowerBound, to: draft.upperBound).day ?? 0
                        Text(DateInterval(start: draft.lowerBound, end: draft.upperBound.addingTimeInterval(1)).formattedDays)
                        Text("· ^[\(days + 1) day](inflect: true)")
                    } else {
                        Text("Click the last day")
                    }
                    Spacer()
                    Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                    Button("Apply") { apply(draft) }
                        .keyboardShortcut(.defaultAction)
                        .disabled(pending != nil)
                }
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
            .padding(14)
        }
    }

    private func apply(_ days: ClosedRange<Date>) {
        range = days
        dismiss()
    }

    private func tap(_ day: Date) {
        if let start = pending {
            draft = min(start, day)...max(start, day)
            pending = nil
        } else {
            pending = day
            draft = day...day
        }
    }
}

private struct MonthGrid: View {
    let month: Date
    let range: ClosedRange<Date>
    let tap: (Date) -> Void

    var body: some View {
        let calendar = Calendar.current
        let count = calendar.range(of: .day, in: .month, for: month)?.count ?? 0
        let lead = (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let weekdays = Array(symbols[(calendar.firstWeekday - 1)...] + symbols[..<(calendar.firstWeekday - 1)])
        VStack(spacing: 8) {
            Text(month, format: .dateTime.month(.wide).year()).font(.headline)
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, weekday in
                    Text(verbatim: weekday).font(.caption).foregroundStyle(.secondary).frame(width: 30, height: 18)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 0), count: 7), spacing: 2) {
                ForEach(-lead..<count, id: \.self) { offset in
                    if offset < 0 {
                        Color.clear.frame(height: 26)
                    } else {
                        let date = calendar.date(byAdding: .day, value: offset, to: month) ?? month
                        Button { tap(date) } label: { DayCell(date: date, range: range) }
                            .buttonStyle(.plain)
                            .disabled(date > .now)
                            .accessibilityLabel(Text(date, format: .dateTime.day().month(.wide).year()))
                    }
                }
            }
        }
    }
}

private struct DayCell: View {
    let date: Date
    let range: ClosedRange<Date>

    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        let isEnd = date == range.lowerBound || date == range.upperBound
        let isFuture = date > .now
        Text(date, format: .dateTime.day())
            .font(.callout.weight(isToday ? .bold : .regular))
            .foregroundStyle(isEnd ? AnyShapeStyle(.white) : isFuture ? AnyShapeStyle(.tertiary) : isToday ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
            .frame(width: 30, height: 26)
            .background {
                ZStack {
                    if range.contains(date), range.lowerBound != range.upperBound {
                        HStack(spacing: 0) {
                            Color.accentColor.opacity(date == range.lowerBound ? 0 : 0.22)
                            Color.accentColor.opacity(date == range.upperBound ? 0 : 0.22)
                        }
                        .frame(height: 24)
                    }
                    if isEnd { Circle().fill(Color.accentColor).frame(width: 24, height: 24) }
                }
            }
            .contentShape(.rect)
    }
}

private extension TrafficPreset {
    var title: Text {
        switch self {
        case .today: Text("Today")
        case .yesterday: Text("Yesterday")
        case .last7Days: Text("Last 7 Days")
        case .thisMonth: Text("This Month")
        case .lastMonth: Text("Last Month")
        case .thisYear: Text("This Year")
        }
    }
}

private extension Date {
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
}

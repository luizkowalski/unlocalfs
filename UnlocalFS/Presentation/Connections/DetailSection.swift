import SwiftUI

struct DetailSection<Content: View>: View {
    var title: Text?
    var footer: Text?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                title.font(.headline).padding(.leading, 10)
            }
            GroupBox {
                VStack(alignment: .leading, spacing: 0) {
                    Group(subviews: content) { rows in
                        ForEach(rows) { row in
                            if row.id != rows.first?.id { Divider() }
                            row.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
            if let footer {
                footer.font(.caption).foregroundStyle(.secondary).padding(.leading, 10)
            }
        }
    }
}

struct DetailColumns<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Group(subviews: content) { rows in
            let height = (rows.count + 1) / 2
            Grid(horizontalSpacing: 28, verticalSpacing: 0) {
                ForEach(0..<height, id: \.self) { index in
                    GridRow(alignment: .top) {
                        cell(rows[index])
                        if index + height < rows.count {
                            cell(rows[index + height])
                        }
                    }
                }
            }
        }
    }

    private func cell(_ row: Subview) -> some View {
        VStack(spacing: 0) {
            Divider()
            row.padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TrailingValueStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label.layoutPriority(1)
            Spacer(minLength: 16)
            configuration.content
        }
    }
}

extension LabeledContentStyle where Self == TrailingValueStyle {
    static var trailingValue: Self { TrailingValueStyle() }
}

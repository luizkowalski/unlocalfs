import SwiftUI
import UnlocalFSDomain

struct ActivityTable<Empty: View>: View {
    let files: [FileActivity]
    @ViewBuilder let empty: Empty

    var body: some View {
        Table(files) {
            TableColumn("Name") { activity in
                ActivityFileName(activity: activity)
            }
            TableColumn("Folder") { activity in
                let folder = (activity.path as NSString).deletingLastPathComponent
                Text(folder).truncationMode(.middle).foregroundStyle(.secondary).help(folder)
            }
            TableColumn("Status") { activity in
                ActivityStatus(activity: activity).font(.caption).foregroundStyle(.secondary)
            }
            .width(min: 150, ideal: 160)
            TableColumn("Size") { activity in
                if activity.size >= 0 {
                    Text(activity.size, format: .byteCount(style: .file))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(74)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: files.count > 1))
        .lineLimit(1)
        .frame(height: files.isEmpty ? 84 : CGFloat(files.count) * 24 + 36)
        .overlay {
            if files.isEmpty { empty.padding(.top, 28) }
        }
        .clipShape(.rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator) }
    }
}

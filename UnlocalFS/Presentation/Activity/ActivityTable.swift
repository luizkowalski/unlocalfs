import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ActivityTable<Empty: View>: View {
    let files: [FileActivity]
    let cancel: (FileActivity) -> Void
    @ViewBuilder let empty: Empty

    var body: some View {
        Table(files) {
            TableColumn("Name") { activity in
                ActivityFileName(activity: activity)
            }
            TableColumn("Folder") { activity in
                Text(activity.folder).truncationMode(.middle).foregroundStyle(.secondary).help(activity.folder)
            }
            TableColumn("Status") { activity in
                HStack(spacing: 6) {
                    ActivityStatus(activity: activity).font(.caption).foregroundStyle(.secondary)
                    if activity.isCancellable {
                        Spacer(minLength: 0)
                        Button { cancel(activity) } label: {
                            Label("Stop upload", systemImage: "xmark.circle.fill")
                                .labelStyle(.iconOnly)
                                .frame(width: 20, height: 20)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Stop upload")
                    }
                }
            }
            .width(min: 170, ideal: 180)
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
        .frame(minHeight: 120, maxHeight: .infinity)
        .overlay {
            if files.isEmpty { empty }
        }
        .clipShape(.rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.separator) }
    }
}

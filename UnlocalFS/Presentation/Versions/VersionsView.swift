import QuickLook
import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct VersionsView: View {
    @Bindable var model: VersionsViewModel
    @State private var selection: FileVersion.ID?

    private var selected: FileVersion? { model.versions.first { $0.id == selection } }

    var body: some View {
        VStack(spacing: 0) {
            if let notice = model.notice {
                Label(notice, systemImage: "info.circle").frame(maxWidth: .infinity, alignment: .leading).padding(10)
                Divider()
            }
            Table(model.versions, selection: $selection) {
                TableColumn("Name") { version in
                    HStack {
                        Text(version.name)
                        if version.isCurrent { Text("Current").foregroundStyle(.secondary) }
                    }
                }
                TableColumn("Saved") { version in Text(version.savedAt, format: .dateTime) }
                TableColumn("Size") { version in Text(version.size, format: .size) }.width(80)
            }
            .contextMenu(forSelectionType: FileVersion.ID.self) { ids in
                if let version = model.versions.first(where: { ids.contains($0.id) }) { actions(for: version) }
            } primaryAction: { ids in
                if let version = model.versions.first(where: { ids.contains($0.id) }) { model.open(version) }
            }
            .overlay {
                if model.loading, model.versions.isEmpty {
                    ProgressView()
                } else if model.versions.isEmpty, model.message == nil {
                    ContentUnavailableView(model.emptyText, systemImage: "clock.arrow.circlepath")
                }
            }
            Divider()
            HStack {
                if let message = model.message {
                    Text(message).foregroundStyle(.red).lineLimit(2).textSelection(.enabled)
                } else if model.working != nil {
                    ProgressView().controlSize(.small)
                }
                Spacer()
                if let selected { actions(for: selected) }
            }
            .padding(10)
        }
        .frame(minWidth: 480, minHeight: 280)
        .task { await model.load() }
        .quickLookPreview($model.preview)
    }

    @ViewBuilder private func actions(for version: FileVersion) -> some View {
        Button("Open") { model.open(version) }.disabled(model.working != nil)
        Button("Restore as Copy") { model.restore(version, asCopy: true) }.disabled(!model.canRestore(version))
        Button("Restore") { model.restore(version, asCopy: false) }.disabled(!model.canRestore(version))
    }
}

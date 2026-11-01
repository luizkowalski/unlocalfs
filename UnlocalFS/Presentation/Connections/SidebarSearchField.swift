import SwiftUI
import UnlocalFSPresentation

struct SidebarSearchField: View {
    @Environment(AppViewModel.self) private var model
    @FocusState private var isFocused: Bool
    var listFocused: FocusState<Bool>.Binding

    var body: some View {
        @Bindable var model = model
        TextField("Search unlocals", text: $model.searchQuery)
            .textFieldStyle(.roundedBorder)
            .focused($isFocused)
            .overlay(alignment: .trailing) {
                if !model.searchQuery.isEmpty {
                    Button("Clear search", systemImage: "xmark.circle.fill", action: clear)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 6)
                }
            }
            .onSubmit(submit)
            .onChange(of: isFocused) { if !isFocused { model.closeSearchIfEmpty() } }
            .focusedValue(\.isEditingSearch, true)
            .task(id: model.searchFocusRequest) { isFocused = true }
            .padding([.horizontal, .top])
    }

    private func clear() {
        model.searchQuery = ""
        isFocused = true
    }

    private func submit() {
        model.submitSearch()
        if !model.visibleConnections.isEmpty { listFocused.wrappedValue = true }
    }
}

extension FocusedValues {
    @Entry var isEditingSearch: Bool?
}

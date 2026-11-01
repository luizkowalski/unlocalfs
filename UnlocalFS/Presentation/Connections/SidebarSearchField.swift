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
            .onSubmit(submit)
            .onChange(of: isFocused) {
                model.isSearchFieldFocused = isFocused
                if !isFocused { model.closeSearchIfEmpty() }
            }
            .onDisappear { model.isSearchFieldFocused = false }
            .task(id: model.searchFocusRequest) { isFocused = true }
            .padding([.horizontal, .top])
    }

    private func submit() {
        model.submitSearch()
        if !model.visibleConnections.isEmpty { listFocused.wrappedValue = true }
    }
}

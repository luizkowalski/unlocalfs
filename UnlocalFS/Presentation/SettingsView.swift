import SwiftUI
import UnlocalFSPresentation

struct SettingsView: View {
    @Environment(AppViewModel.self) private var model
    @AppStorage(AppDelegate.showsMenuBarExtraKey) private var showsMenuBarExtra = true

    var body: some View {
        Form {
            Toggle("Open at Login", isOn: Binding(get: { model.opensAtLogin }, set: { model.setOpensAtLogin($0) }))
            Toggle(isOn: $showsMenuBarExtra) {
                Text("Show in Menu Bar")
                Text("When the menu bar icon is off, UnlocalFS stays in the Dock after you close its window.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize()
        .onAppear { model.syncOpensAtLogin() }
    }
}

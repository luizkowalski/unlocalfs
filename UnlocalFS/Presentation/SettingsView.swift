import FinderSync
import SwiftUI
import UnlocalFSPresentation

struct SettingsView: View {
    @Environment(AppViewModel.self) private var model
    @AppStorage(AppDelegate.showsMenuBarExtraKey) private var showsMenuBarExtra = true
    @State private var finderExtensionEnabled = FIFinderSyncController.isExtensionEnabled

    var body: some View {
        Form {
            Toggle("Open at Login", isOn: Binding(get: { model.opensAtLogin }, set: { model.setOpensAtLogin($0) }))
            Toggle(isOn: $showsMenuBarExtra) {
                Text("Show in Menu Bar")
                Text("When the menu bar icon is off, UnlocalFS stays in the Dock after you close its window.")
            }
            LabeledContent {
                if finderExtensionEnabled {
                    Text("On")
                } else {
                    Button("Turn On…") { FIFinderSyncController.showExtensionManagementInterface() }
                }
            } label: {
                Text("Finder Extension")
                Text("Shows upload status in Finder and adds Copy Share Link and Duplicate on Server to its right-click menu.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize()
        .onAppear { model.syncOpensAtLogin() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            finderExtensionEnabled = FIFinderSyncController.isExtensionEnabled
        }
    }
}

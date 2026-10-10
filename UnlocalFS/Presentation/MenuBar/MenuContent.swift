import AppKit
import SwiftUI
import UnlocalFSPresentation

struct MenuContent: View {
    @Environment(AppViewModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open UnlocalFS", action: openMain)
        Divider()
        if model.connections.isEmpty { Text("No connections yet") }
        ForEach(model.connections) { connection in
            Menu(connection.name) {
                Text(model.statusText(connection))
                Button(model.toggleTitle(connection)) {
                    Task {
                        await model.toggle(connection, opensFinder: true)
                        if model.needsMainWindow(connection) { openMain() }
                    }
                }
                .disabled(!model.canToggle(connection))
                Button("Open in Finder") { model.openDrive(connection) }
                    .disabled(!model.canOpen(connection))
                Button("Refresh Files") { Task { await model.refreshFiles(connection) } }
                    .disabled(!model.canOpen(connection))
            }
        }
        Divider()
        Toggle("Open at Login", isOn: Binding(get: { model.opensAtLogin }, set: { model.setOpensAtLogin($0) }))
        Button("Quit UnlocalFS") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }

    private func openMain() {
        openWindow(id: "main")
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }
}

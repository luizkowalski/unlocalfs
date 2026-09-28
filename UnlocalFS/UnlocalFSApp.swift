import AppKit
import SwiftUI
import UnlocalFSCore

@main struct UnlocalFSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("UnlocalFS", id: "main") {
            MainView().environment(delegate.model)
        }
        .defaultSize(width: 860, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Connection…") { delegate.model.edit(Connection()) }
                    .keyboardShortcut("n")
                    .disabled(!delegate.model.ready)
                Button("Edit Connection…") {
                    if let connection = delegate.model.selected { delegate.model.edit(connection) }
                }
                .keyboardShortcut("e")
                .disabled(delegate.model.selected.map { !delegate.model.canEdit($0) } ?? true)
                Button("Duplicate Connection…") {
                    if let connection = delegate.model.selected { delegate.model.duplicate(connection) }
                }
                .keyboardShortcut("d")
                .disabled(delegate.model.selected == nil)
            }
        }
        MenuBarExtra {
            MenuContent().environment(delegate.model)
        } label: {
            MenuBarIcon(activity: delegate.model.activity)
        }
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var checkingQuit = false

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        sender.setActivationPolicy(.accessory)
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !checkingQuit else { return .terminateCancel }
        checkingQuit = true
        Task {
            let allowed = await model.canQuit()
            checkingQuit = false
            if !allowed {
                sender.activate()
                let alert = NSAlert()
                alert.messageText = "UnlocalFS is still running"
                alert.informativeText = model.alert ?? "Disconnect your drives before quitting."
                model.alert = nil
                alert.runModal()
            }
            sender.reply(toApplicationShouldTerminate: allowed)
        }
        return .terminateLater
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        sender.setActivationPolicy(.regular)
        if !flag { sender.windows.first?.makeKeyAndOrderFront(nil) }
        return true
    }
}

private struct MenuContent: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open UnlocalFS") {
            openWindow(id: "main")
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        if model.connections.isEmpty { Text("No connections yet") }
        ForEach(model.connections) { connection in
            Menu(connection.name) {
                Text(model.statusText(connection))
                Button(model.isActive(connection) ? "Disconnect" : "Connect") {
                    Task { await model.toggle(connection) }
                }
                .disabled(!model.canToggle(connection))
                Button("Open in Finder") { model.openDrive(connection) }
                    .disabled(model.statuses[connection.id]?.isMounted != true)
            }
        }
        Divider()
        Toggle("Open at Login", isOn: Binding(get: { model.opensAtLogin }, set: model.setOpensAtLogin))
        Button("Quit UnlocalFS") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}

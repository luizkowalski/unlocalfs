import AppKit
import Network
import OSLog
import SwiftUI
import UnlocalFSDomain
import UnlocalFSFinderLink
import UnlocalFSPresentation

@main struct UnlocalFSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @FocusedValue(\.isEditingSearch) private var isEditingSearch
    @AppStorage(AppDelegate.showsMenuBarExtraKey) private var showsMenuBarExtra = AppDelegate.showsMenuBarExtraByDefault
    @Environment(\.openWindow) private var openWindow

    private var model: AppViewModel { delegate.model }

    var body: some Scene {
        Window("UnlocalFS", id: "main") {
            MainView().environment(delegate.model).environment(delegate.viewModels)
        }
        .defaultSize(width: 860, height: 680)
        .onChange(of: model.needsMainWindow) { _, needed in
            if needed { openWindow.main() }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About UnlocalFS") {
                    let version = Bundle.main.object(forInfoDictionaryKey: "RcloneVersion") as? String ?? ""
                    let credits = NSAttributedString(string: "rclone \(version)", attributes: [
                        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                        .foregroundColor: NSColor.labelColor,
                    ])
                    NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("New Connection…") { model.edit(Connection()) }
                    .keyboardShortcut("n")
                    .disabled(!model.canStartEditing)
                Button("Edit Connection…") { selected(model.edit) }
                    .keyboardShortcut("i")
                    .disabled(!model.canStartEditing || !selectedAllows(model.canEdit))
                Button("Duplicate Connection…") { selected(model.duplicate) }
                    .keyboardShortcut("d")
                    .disabled(!model.canStartEditing || model.selected == nil)
                Button("Delete Connection…", role: .destructive) { model.deleting = model.selected }
                    .keyboardShortcut(.delete)
                    .disabled(!model.canStartEditing || isEditingSearch != nil || !selectedAllows(model.canEdit))
            }
            CommandGroup(after: .textEditing) {
                Button("Find Drive…") { model.openSearch() }
                    .keyboardShortcut("f")
                    .disabled(!model.canStartEditing)
            }
            SidebarCommands()
            InspectorCommands()
            CommandMenu("Drive") { driveCommands }
        }
        Settings {
            SettingsView().environment(delegate.model)
        }
        MenuBarExtra(isInserted: $showsMenuBarExtra) {
            MenuContent().environment(delegate.model)
        } label: {
            MenuBarIcon(activity: model.activity)
        }
        .onChange(of: showsMenuBarExtra) {
            if !showsMenuBarExtra { NSApp.setActivationPolicy(.regular) }
        }
    }

    @ViewBuilder private var driveCommands: some View {
        Button("Connect") { selected { await model.activate($0) } }
            .keyboardShortcut("k")
            .disabled(!selectedAllows(model.canConnect))
        Button("Disconnect") { selected { await model.disconnect($0) } }
            .keyboardShortcut("e")
            .disabled(isEditingSearch != nil || !selectedAllows(model.canDisconnect))
        Button("Reconnect") { selected { await model.reconnect($0) } }
            .disabled(!selectedAllows(model.canReconnect))
        Button("Disconnect All") { Task { await model.disconnectAll() } }
            .disabled(!model.canDisconnectAll)
        Divider()
        Button("Open in Finder") { selected(model.openDrive) }
            .keyboardShortcut("o")
            .disabled(!selectedAllows(model.canOpen))
        Button("Refresh Files") { selected { await model.refreshFiles($0) } }
            .keyboardShortcut("r")
            .disabled(!selectedAllows(model.canOpen))
        Divider()
        Button("Export rclone Config…") { selected { await model.exportRcloneConfig($0) } }
            .disabled(!selectedAllows(\.exportsRcloneConfig))
        Button("Clean Up Unfinished Uploads…") { selected { await model.reviewUnfinishedUploads($0) } }
            .disabled(!selectedAllows(model.canCleanUpUploads))
        Button("Show Log") { selected(model.openLog) }
            .disabled(model.selected == nil)
    }

    private func selected(_ action: (Connection) -> Void) {
        if let connection = model.selected { action(connection) }
    }

    private func selected(_ action: @escaping (Connection) async -> Void) {
        guard let connection = model.selected else { return }
        Task { await action(connection) }
    }

    private func selectedAllows(_ rule: (Connection) -> Bool) -> Bool {
        model.selected.map(rule) ?? false
    }
}

@MainActor
extension OpenWindowAction {
    func main() {
        self(id: "main")
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    static let showsMenuBarExtraKey = "showsMenuBarExtra"
    static let showsMenuBarExtraByDefault = true
    let dependencies = AppDependencies.live()
    var model: AppViewModel { dependencies.model }
    var viewModels: ViewModelFactory { dependencies.viewModels }
    private var requester = NSWorkspace.shared.frontmostApplication
    private var serviceRequester: NSRunningApplication?
    private let pathMonitor = NWPathMonitor()
    private var finderPort: FinderSyncPort?

    func applicationDidFinishLaunching(_: Notification) {
        Task { await model.run() }
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(willSleep), name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        center.addObserver(self, selector: #selector(applicationActivated), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let available = path.status == .satisfied
            Task { @MainActor [weak self] in await self?.model.networkChanged(available: available) }
        }
        pathMonitor.start(queue: DispatchQueue(label: "net.luizkowalski.unlocalfs.network"))
        NSApp.servicesProvider = self
        do {
            finderPort = try FinderSyncPort { [model] in model.reply(to: $0) }
        } catch {
            Logger().error("Finder extension unavailable: \(error.localizedDescription, privacy: .public)")
        }
        NSUpdateDynamicServices()
    }

    @objc private func willSleep(_: Notification) { model.willSleep() }

    @objc private func didWake(_: Notification) {
        Task { await model.didWake() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let showsMenuBarExtra = UserDefaults.standard.object(forKey: Self.showsMenuBarExtraKey) as? Bool ?? Self.showsMenuBarExtraByDefault
        sender.setActivationPolicy(showsMenuBarExtra ? .accessory : .regular)
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard model.beginQuit() else { return .terminateCancel }
        Task {
            var allowed: Bool
            switch await model.quitDecision() {
            case .quit:
                allowed = true
            case .disconnect:
                sender.activate()
                let alert = NSAlert()
                alert.messageText = String(localized: "Disconnect all drives before quitting?")
                alert.addButton(withTitle: String(localized: "Disconnect All and Quit"))
                alert.addButton(withTitle: String(localized: "Cancel"))
                allowed = alert.runModal() == .alertFirstButtonReturn
                if allowed, let failure = await model.disconnectForQuit() {
                    let alert = NSAlert()
                    alert.messageText = String(localized: "“\(failure.connection.name)” couldn’t be disconnected.")
                    alert.informativeText = failure.error.localizedDescription
                    alert.runModal()
                    allowed = false
                }
            case let .wait(message):
                sender.activate()
                let alert = NSAlert()
                alert.messageText = String(localized: "UnlocalFS is still running")
                alert.informativeText = message
                alert.runModal()
                allowed = false
            }
            if allowed { await model.stopSignInsForQuit() } else { model.cancelQuit() }
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

extension AppDelegate {
    @objc func copyShareLink(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let expiry = userData.flatMap(ShareLinkExpiry.init) else {
            refuseService(error)
            return
        }
        runService(on: pasteboard, error: error) { await self.model.copyShareLinks(for: $0, expiry: expiry) }
    }

    @objc func duplicateOnServer(_ pasteboard: NSPasteboard, userData _: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        runService(on: pasteboard, error: error) { await self.model.duplicateOnServer($0) }
    }

    private func runService(
        on pasteboard: NSPasteboard, error: AutoreleasingUnsafeMutablePointer<NSString?>, _ action: @escaping @MainActor ([URL]) async -> Void,
    ) {
        guard let files = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
              !files.isEmpty
        else {
            refuseService(error)
            return
        }
        serviceRequester = requester == NSRunningApplication.current ? nil : requester
        if NSApp.isActive { returnServiceFocus() }
        Task { await action(files) }
        Task {
            try? await Task.sleep(for: .seconds(2))
            serviceRequester = nil
        }
    }

    private func refuseService(_ error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        error.pointee = String(localized: "Select files in an UnlocalFS drive.") as NSString
    }

    @objc private func applicationActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        if app == .current {
            returnServiceFocus()
            model.syncOpensAtLogin()
        } else {
            requester = app
        }
    }

    private func returnServiceFocus() {
        guard let serviceRequester else { return }
        self.serviceRequester = nil
        NSApp.yieldActivation(to: serviceRequester)
        serviceRequester.activate()
    }
}

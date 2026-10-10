import AppKit
import Network
import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

@main struct UnlocalFSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("UnlocalFS", id: "main") {
            MainView().environment(delegate.model).environment(delegate.viewModels)
        }
        .defaultSize(width: 860, height: 680)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About UnlocalFS") {
                    let version = Bundle.main.object(forInfoDictionaryKey: "RcloneVersion") as? String ?? ""
                    let credits = NSAttributedString(string: "rclone \(version)", attributes: [
                        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                        .foregroundColor: NSColor.labelColor
                    ])
                    NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
                }
            }
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
                Button("Delete Connection…", role: .destructive) {
                    delegate.model.deleting = delegate.model.selected
                }
                .keyboardShortcut(.delete)
                .disabled(delegate.model.selected.map { !delegate.model.canEdit($0) } ?? true)
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
    let dependencies = AppDependencies.live()
    var model: AppViewModel { dependencies.model }
    var viewModels: ViewModelFactory { dependencies.viewModels }
    private var requester = NSWorkspace.shared.frontmostApplication
    private var serviceRequester: NSRunningApplication?
    private var checkingQuit = false
    private let pathMonitor = NWPathMonitor()
    private var refreshTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        refreshTask = Task { await model.run() }
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
        NSUpdateDynamicServices()
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTask?.cancel()
        pathMonitor.cancel()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func willSleep(_ notification: Notification) { model.willSleep() }

    @objc private func didWake(_ notification: Notification) {
        Task { await model.didWake() }
    }

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
                alert.messageText = String(localized: "UnlocalFS is still running")
                alert.informativeText = model.alert ?? String(localized: "Disconnect your drives before quitting.")
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

extension AppDelegate {
    @objc func copyShareLink(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let expiry = userData.flatMap(ShareLinkExpiry.init) else {
            refuseService(error)
            return
        }
        runService(on: pasteboard, error: error) { await self.model.copyShareLinks(for: $0, expiry: expiry) }
    }

    @objc func duplicateOnServer(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        runService(on: pasteboard, error: error) { await self.model.duplicateOnServer($0) }
    }

    private func runService(
        on pasteboard: NSPasteboard, error: AutoreleasingUnsafeMutablePointer<NSString?>, _ action: @escaping @MainActor ([URL]) async -> Void
    ) {
        guard let files = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
              !files.isEmpty else {
            refuseService(error)
            return
        }
        serviceRequester = requester == NSRunningApplication.current ? nil : requester
        if NSApp.isActive { returnServiceFocus() }
        Task {
            defer { serviceRequester = nil }
            await action(files)
        }
    }

    private func refuseService(_ error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        error.pointee = String(localized: "Select files in an UnlocalFS drive.") as NSString
    }

    @objc private func applicationActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        if app == .current {
            returnServiceFocus()
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

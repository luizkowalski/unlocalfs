import AppKit
import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

@MainActor final class VersionsWindows: NSObject, NSWindowDelegate {
    private let fileVersions: FileVersionsUseCase
    private var open: [VersionsTarget.ID: (window: NSWindow, model: VersionsViewModel)] = [:]

    init(fileVersions: FileVersionsUseCase) {
        self.fileVersions = fileVersions
    }

    func show(_ target: VersionsTarget) {
        NSApp.bringToFront()
        if let window = open[target.id]?.window {
            bringForward(window)
            return
        }
        let model = VersionsViewModel(target: target, fileVersions: fileVersions)
        let window = NSWindow(contentViewController: NSHostingController(rootView: VersionsView(model: model)))
        window.title = model.title
        window.setContentSize(NSSize(width: 620, height: 380))
        window.isReleasedWhenClosed = false
        window.delegate = self
        open[target.id] = (window, model)
        window.center()
        bringForward(window)
    }

    private func bringForward(_ window: NSWindow) {
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func windowWillClose(_ notification: Notification) {
        guard let id = open.first(where: { $0.value.window === notification.object as? NSWindow })?.key else { return }
        open.removeValue(forKey: id)?.model.close()
    }
}

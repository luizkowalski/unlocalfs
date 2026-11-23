import AppKit
import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

@MainActor final class VersionsWindows: NSObject, NSWindowDelegate {
    var makeModel: ((VersionsTarget) -> VersionsViewModel)?
    private var open: [VersionsTarget.ID: (window: NSWindow, model: VersionsViewModel)] = [:]

    func show(_ target: VersionsTarget) {
        NSApp.activate()
        if let window = open[target.id]?.window {
            window.makeKeyAndOrderFront(nil)
            return
        }
        guard let model = makeModel?(target) else { return }
        let window = NSWindow(contentViewController: NSHostingController(rootView: VersionsView(model: model)))
        window.title = model.title
        window.setContentSize(NSSize(width: 620, height: 380))
        window.isReleasedWhenClosed = false
        window.delegate = self
        open[target.id] = (window, model)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let id = open.first(where: { $0.value.window === notification.object as? NSWindow })?.key else { return }
        open.removeValue(forKey: id)?.model.close()
    }
}

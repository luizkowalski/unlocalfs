import AppKit
import UnlocalFSCore

@MainActor final class ShareLinkProvider: NSObject {
    private let model: AppModel
    private var requester = NSWorkspace.shared.frontmostApplication
    private var returnsFocus = false

    init(model: AppModel) {
        self.model = model
        super.init()
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(applicationActivated), name: NSWorkspace.didActivateApplicationNotification, object: nil
        )
    }

    @objc func copyShareLink(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        returnsFocus = true
        guard let files = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
              !files.isEmpty, let expiry = userData.flatMap(ShareLinkExpiry.init) else {
            error.pointee = "Select files in an UnlocalFS drive."
            return
        }
        Task { await model.copyShareLinks(for: files, expiry: expiry) }
    }

    @objc private func applicationActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        guard app == .current else {
            requester = app
            return
        }
        if returnsFocus, let requester {
            returnsFocus = false
            NSApp.yieldActivation(to: requester)
            requester.activate()
        }
    }
}

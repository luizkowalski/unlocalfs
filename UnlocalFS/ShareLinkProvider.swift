import AppKit
import UnlocalFSCore

@MainActor final class ShareLinkProvider: NSObject {
    private let model: AppModel

    init(model: AppModel) {
        self.model = model
    }

    @objc func copyShareLink(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let files = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
              !files.isEmpty, let expiry = userData.flatMap(ShareLinkExpiry.init) else {
            error.pointee = "Select files in an UnlocalFS drive."
            return
        }
        Task { await model.copyShareLinks(for: files, expiry: expiry) }
    }
}

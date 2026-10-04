import Foundation

/// English text is the localization key; the en table is empty, so English
/// output is the key itself. Test suites pin `bundle` to the module's
/// `en.lproj` sub-bundle so string assertions pass on any host locale.
enum L10n {
    nonisolated(unsafe) static var bundle: Bundle = .module

    static func text(_ key: String.LocalizationValue) -> String {
        String(localized: key, table: "Localizable", bundle: bundle)
    }

    /// The module's `en.lproj` sub-bundle, used by tests to pin English output.
    static var englishBundle: Bundle {
        if let url = bundle.url(forResource: "en", withExtension: "lproj"), let english = Bundle(url: url) {
            return english
        }
        return bundle
    }

    // MARK: Drive status text

    static var working: String { text("Working…") }
    static var needsReconnect: String { text("Needs reconnect") }
    static var needsAttention: String { text("Needs attention") }
    static var checking: String { text("Checking…") }
    static var networkUnavailable: String { text("Network unavailable") }
    static var uploadNeedsAttention: String { text("Upload needs attention") }
    static func uploadsPending(_ count: Int) -> String {
        String(format: text(count == 1 ? "%1$@ upload pending" : "%1$@ uploads pending"), String(count))
    }
    static var connected: String { text("Connected") }
    static var ejected: String { text("Ejected · disconnect to stop") }
    static var disconnected: String { text("Disconnected") }

    // MARK: Toggle titles

    static var reconnect: String { text("Reconnect") }
    static var disconnect: String { text("Disconnect") }
    static var connect: String { text("Connect") }

    // MARK: Upload notices

    static var uploadsPendingKeepDriveConnected: String {
        text("Uploads pending. Keep this drive connected until uploads finish.")
    }
    static var uploadsPendingKeepAppRunning: String {
        text("Uploads pending. Keep UnlocalFS running until they finish, then disconnect again.")
    }

    // MARK: Share-link notifications

    static var linkCopied: String { text("Link copied") }
    static func linksCopied(_ count: String) -> String { text("\(count) links copied") }
    static func anyoneCanDownload(for expiryTitle: String) -> String {
        text("Anyone with the link can download for \(expiryTitle).")
    }
    static func couldNotCopyLink(to fileName: String) -> String {
        text("Could not copy a link to \(fileName)")
    }
    static var couldNotCopyShareLinks: String { text("Could not copy share links") }

    // MARK: Upload notifications

    static func uploadsFailed(on driveName: String) -> String {
        text("Uploads failed on \(driveName)")
    }
    static var uploadsFailedBody: String {
        text("Some files could not upload. Keep the drive connected while UnlocalFS tries again.")
    }
    static func finishedUploading(_ driveName: String) -> String {
        text("\(driveName) finished uploading")
    }
    static var canDisconnectNow: String { text("You can disconnect it now.") }

    // MARK: Editor titles

    static var duplicateConnection: String { text("Duplicate connection") }
    static var addConnection: String { text("Add connection") }
    static var editConnection: String { text("Edit connection") }
}

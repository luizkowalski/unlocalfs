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

    // MARK: MountService

    static var alreadyConnecting: String { text("This drive is already connecting.") }
    static var alreadyRunning: String { text("This drive is already running. Disconnect it first.") }
    static func mountFolderContainsFiles(_ path: String) -> String {
        text("The mount folder contains files. Move them before connecting: \(path)")
    }
    static func couldNotOpenLog(_ reason: String) -> String {
        text("Could not open the drive log: \(reason)")
    }
    static var couldNotMount: String { text("The drive could not mount. Open its log for details.") }
    static var mountTimedOut: String { text("The drive took too long to mount. Open its log for details.") }
    static var controlServiceUnavailableReconnect: String { text("The drive's control service is unavailable. Reconnect to restore the drive. Its cache will be kept.") }
    static func controlServiceUnavailable(_ details: String) -> String {
        text("The drive's control service is unavailable. Its cache will be kept.\n\n\(details)")
    }
    static var couldNotStopOldService: String { text("Could not stop the old drive service because its process could not be identified. The cache was kept.") }
    static func cannotReadFile(_ name: String, _ path: String) -> String {
        text("UnlocalFS cannot read the \(name): \(path)\nChoose a file that exists and that you can read.")
    }
    static var trustedHostsFileName: String { text("trusted-hosts file") }
    static var privateKeyFileName: String { text("private key file") }
    static var agentUnavailable: String { text("ssh-agent is not available. Start your ssh-agent and load a key, or enter the agent's socket path in the connection.") }
    static var hostKeyChanged: String { text("its host key changed") }
    static var hostKeyNotTrusted: String { text("its host key is not trusted yet") }
    static func untrustedHost(_ reason: String, trustedHostsPath: String, details: String) -> String {
        text("""
        Could not trust this server because \(reason). Check the server's host key fingerprint with its administrator, \
        then fix its entry in \(trustedHostsPath). UnlocalFS never changes this file.\n\n\(details)
        """)
    }
    static var folderEndsWithSpace: String { text("This drive's folder ends with a space, which rclone config files cannot keep. Rename the folder to export a config.") }
    static var reconnectForLinks: String { text("Reconnect the drive to create links. UnlocalFS can only create links through a connected drive.") }
    static func reconnectToCheckUploads(_ details: String) -> String {
        text("Reconnect the drive to create links. UnlocalFS could not check whether the file is still uploading.\n\n\(details)")
    }
    static var fileStillUploading: String { text("This file is still uploading. Wait for it to finish, then copy the link again.") }
    static func couldNotCreateLinkUploading(_ details: String) -> String {
        text("Could not create a link. If the file is still uploading, wait for it to finish.\n\n\(details)")
    }
    static var couldNotCreateLink: String { text("Could not create a link. Try again.") }
    static func couldNotEject(_ details: String) -> String {
        text("Could not eject the drive. Close files using it and try again.\n\n\(details)")
    }
    static var driveStillMounted: String { text("The drive is still mounted. Close files using it and try again.") }
    static var driveStillStopping: String { text("The drive is still stopping. Wait a moment and try disconnecting again.") }

    // MARK: Command

    static var commandTimedOut: String { text("The command timed out. Try again.") }
    static var commandFailed: String { text("The command failed. Try again.") }

    // MARK: Keychain

    static var keychainUnexpectedData: String { text("Keychain returned unexpected data.") }
    static func keychainError(_ status: String) -> String {
        text("Keychain error \(status)")
    }
}

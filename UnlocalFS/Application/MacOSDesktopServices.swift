import AppKit
import OSLog
import ServiceManagement
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation
import UserNotifications

@MainActor struct MacOSDesktopServices: DesktopServices {
    let paths: AppPaths
    var opensAtLogin: Bool { SMAppService.mainApp.status == .enabled }

    func setOpensAtLogin(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
    }

    func mountLocation(_ connection: Connection) -> URL { paths.mount(connection) }
    func openDrive(_ connection: Connection) { NSWorkspace.shared.open(paths.mount(connection)) }
    func openLog(_ connection: Connection) { NSWorkspace.shared.open(paths.log(connection)) }

    nonisolated static func readServiceAccountKey(_ result: Result<URL, any Error>) async -> Result<Data, any Error> {
        await Task.detached {
            Result { try Data(contentsOf: result.get()) }
        }.value
    }

    func copyShareLinks(_ links: [URL]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(links.map(\.absoluteString).joined(separator: "\n"), forType: .string)
    }

    func chooseRcloneConfigDestination(for connection: Connection) -> RcloneConfigDestination? {
        let panel = NSSavePanel()
        panel.title = String(localized: "Export rclone Config")
        panel.message = String(localized: "Use this file with rclone to read \(connection.name) without UnlocalFS.")
        panel.nameFieldStringValue = "\(connection.name) rclone.conf"
        let includesSecrets = NSButton(checkboxWithTitle: Self.secretsTitle(for: connection), target: nil, action: nil)
        let caption = NSTextField(wrappingLabelWithString: Self.exportCaption(for: connection))
        caption.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        caption.textColor = .secondaryLabelColor
        caption.preferredMaxLayoutWidth = 360
        let accessory = NSStackView(views: [includesSecrets, caption])
        accessory.orientation = .vertical
        accessory.alignment = .leading
        accessory.edgeInsets = NSEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        accessory.setFrameSize(accessory.fittingSize)
        panel.accessoryView = accessory
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return RcloneConfigDestination(url: url, includesSecrets: includesSecrets.state == .on)
    }

    private static func secretsTitle(for connection: Connection) -> String {
        switch connection.backend {
        case .s3Compatible: String(localized: "Include keys and password")
        case .sftp: String(localized: "Include saved passwords")
        case .gcs: String(localized: "Include service-account key")
        }
    }

    private static func exportCaption(for connection: Connection) -> String {
        switch connection.backend {
        case .s3Compatible:
            return String(localized: "Anyone with the file can read this drive. The password is only obscured, not encrypted.")
        case .gcs:
            return String(localized: "Anyone with the file can read this drive and use its service-account key. The password is only obscured, not encrypted.")
        case .sftp:
            return connection.sftp.authentication == .agent
                ? String(
                    localized: """
                    Anyone with the file can read this drive. Passwords are only obscured, not encrypted. The file points to your \
                    trusted-hosts file and needs a running ssh-agent. Copy the trusted-hosts file to the other Mac and adjust the path.
                    """
                )
                : String(
                    localized: """
                    Anyone with the file can read this drive. Passwords are only obscured, not encrypted. The file points to your \
                    trusted-hosts file and private key file. Copy them to the other Mac and adjust the paths.
                    """
                )
        }
    }

    func notify(title: String, body: String, fallbackToAlert: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                if try await center.requestAuthorization(options: [.alert]) {
                    try await center.add(request)
                    return
                }
            } catch {
                Logger().error("Could not show a notification: \(error, privacy: .public)")
            }
            if fallbackToAlert {
                NSApp.activate()
                let alert = NSAlert()
                alert.messageText = title
                alert.informativeText = body
                alert.runModal()
            }
        }
    }
}

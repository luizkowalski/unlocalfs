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

    func copyShareLinks(_ links: [URL]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(links.map(\.absoluteString).joined(separator: "\n"), forType: .string)
    }

    func chooseRcloneConfigDestination(for connection: Connection) -> RcloneConfigDestination? {
        let panel = NSSavePanel()
        panel.title = "Export rclone Config"
        panel.message = "Use this file with rclone to read \(connection.name) without UnlocalFS."
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
        case .s3Compatible: "Include keys and password"
        case .sftp: "Include saved passwords"
        case .gcs: "Include service-account key"
        }
    }

    private static func exportCaption(for connection: Connection) -> String {
        switch connection.backend {
        case .s3Compatible:
            return "Anyone with the file can read this drive. The password is only obscured, not encrypted."
        case .gcs:
            return "Anyone with the file can read this drive and use its service-account key. The password is only obscured, not encrypted."
        case .sftp:
            let dependency = connection.sftp.authentication == .agent ? "needs a running ssh-agent" : "private key file"
            return """
            Anyone with the file can read this drive. Passwords are only obscured, not encrypted. \
            The file points to your trusted-hosts file and \(dependency). Copy them to the other Mac and adjust the paths.
            """
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

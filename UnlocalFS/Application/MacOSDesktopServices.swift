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
        let includesSecrets = NSButton(checkboxWithTitle: "Include keys and password", target: nil, action: nil)
        let caption = NSTextField(wrappingLabelWithString: "Anyone with the file can read this drive. The password is only obscured, not encrypted.")
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

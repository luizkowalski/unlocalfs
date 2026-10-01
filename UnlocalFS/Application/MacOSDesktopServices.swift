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
    func cacheLocation(_ connection: Connection) -> URL { paths.cache(connection) }
    func openDrive(_ connection: Connection) { NSWorkspace.shared.open(paths.mount(connection)) }
    func openLog(_ connection: Connection) { NSWorkspace.shared.open(paths.log(connection)) }

    func copyShareLinks(_ links: [URL]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(links.map(\.absoluteString).joined(separator: "\n"), forType: .string)
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

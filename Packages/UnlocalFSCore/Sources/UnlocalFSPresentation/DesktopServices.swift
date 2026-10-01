import Foundation
import UnlocalFSDomain

@MainActor public protocol DesktopServices {
    var opensAtLogin: Bool { get }
    func setOpensAtLogin(_ enabled: Bool) throws
    func mountLocation(_ connection: Connection) -> URL
    func cacheLocation(_ connection: Connection) -> URL
    func openDrive(_ connection: Connection)
    func openLog(_ connection: Connection)
    func copyShareLinks(_ links: [URL])
    func notify(title: String, body: String, fallbackToAlert: Bool)
}

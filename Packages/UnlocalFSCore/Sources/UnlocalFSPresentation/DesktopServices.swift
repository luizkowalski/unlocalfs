import Foundation
import UnlocalFSDomain

@MainActor public protocol DesktopServices {
    var opensAtLogin: Bool { get }
    func setOpensAtLogin(_ enabled: Bool) throws
    func mountLocation(_ connection: Connection) -> URL
    func openDrive(_ connection: Connection)
    func openLog(_ connection: Connection)
    func copyShareLinks(_ links: [URL])
    func chooseRcloneConfigDestination(for connection: Connection) -> RcloneConfigDestination?
    func notify(title: String, body: String, fallbackToAlert: Bool)
}

public struct RcloneConfigDestination {
    public let url: URL
    public let includesSecrets: Bool

    public init(url: URL, includesSecrets: Bool) {
        self.url = url
        self.includesSecrets = includesSecrets
    }
}

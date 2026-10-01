import Foundation
import UnlocalFSDomain

public struct AppPaths: Sendable {
    public let config: URL
    public let support: URL
    public let mounts: URL
    public let logs: URL

    public static let standard = AppPaths(
        config: .homeDirectory.appending(path: ".unlocalfs/config.json"),
        support: .applicationSupportDirectory.appending(path: "UnlocalFS"),
        mounts: .homeDirectory.appending(path: "UnlocalFS"),
        logs: .libraryDirectory.appending(path: "Logs/UnlocalFS")
    )

    public init(config: URL, support: URL, mounts: URL, logs: URL) {
        self.config = config
        self.support = support
        self.mounts = mounts
        self.logs = logs
    }

    public func prepare() throws {
        for directory in [support, sockets, logs, mounts] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: sockets.path)
    }

    public func mount(_ connection: Connection) -> URL { mounts.appending(path: connection.name) }
    public func drive(containing file: URL, among connections: [Connection]) -> (connection: Connection, path: String)? {
        let components = file.standardizedFileURL.pathComponents
        for connection in connections {
            let root = mount(connection).standardizedFileURL.pathComponents
            if components.count > root.count, components.starts(with: root) {
                return (connection, components.dropFirst(root.count).joined(separator: "/"))
            }
        }
        return nil
    }
    public func cache(_ connection: Connection) -> URL { support.appending(path: "cache/\(connection.id.uuidString)") }
    public func removeCache(_ connection: Connection) {
        try? FileManager.default.removeItem(at: cache(connection))
    }
    public func log(_ connection: Connection) -> URL { logs.appending(path: "\(connection.id.uuidString).log") }
    public func socket(_ connection: Connection) -> URL { sockets.appending(path: "\(connection.id.uuidString.prefix(18)).sock") }
    public func pidFile(_ connection: Connection) -> URL { socket(connection).appendingPathExtension("pid") }

    private var sockets: URL { support.appending(path: "run") }
}

import Foundation

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
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: sockets.path)
    }

    public func mount(_ connection: Connection) -> URL { mounts.appending(path: connection.name) }
    public func cache(_ connection: Connection) -> URL { support.appending(path: "cache/\(connection.id.uuidString)") }
    public func log(_ connection: Connection) -> URL { logs.appending(path: "\(connection.id.uuidString).log") }
    public func socket(_ connection: Connection) -> URL {
        sockets.appending(path: "\(connection.id.uuidString.prefix(18)).sock")
    }

    private var sockets: URL { support.appending(path: "run") }
}

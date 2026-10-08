import Foundation

struct MountCommand {
    private static let logMaxSize = "5M"
    private static let logMaxBackups = 2
    private static let readChunkStreams = 4
    private static let readChunkSize = "4M"
    private static let readBufferSize = "1M"

    let remote: RcloneRemote
    let paths: AppPaths

    var arguments: [String] {
        let connection = remote.connection
        var arguments = [
            "nfsmount", remote.target, paths.mount(connection).path,
            "--config", "/dev/null", "--vfs-cache-mode", "full",
            "--cache-dir", paths.cache(connection).path, "--vfs-cache-max-size", "\(connection.cacheLimit)B", "--vfs-cache-max-age", "off",
            "--vfs-cache-min-free-space", connection.minimumFreeSpace > 0 ? "\(connection.minimumFreeSpace)B" : "off",
            "--vfs-fast-fingerprint", "--buffer-size", Self.readBufferSize, "--transfers", "\(connection.transfers)", "--default-time", Date.now.ISO8601Format(),
            "--rc", "--rc-no-auth",
            "--rc-addr", "unix://\(paths.socket(connection).path)", "--log-level", "INFO",
            "--log-file", paths.log(connection).path, "--log-file-max-size", Self.logMaxSize, "--log-file-max-backups", "\(Self.logMaxBackups)"
        ]
        if connection.backend != .sftp {
            arguments += ["--vfs-read-chunk-streams", "\(Self.readChunkStreams)", "--vfs-read-chunk-size", Self.readChunkSize]
        }
        if connection.bandwidthLimit > 0 { arguments += ["--bwlimit", "\(connection.bandwidthLimit)B"] }
        if connection.readOnly { arguments.append("--read-only") }
        return arguments
    }

    var environment: [String: String] {
        remote.environment.merging(["UNLOCALFS_VOLUME_NAME": remote.connection.name]) { _, new in new }
    }
}

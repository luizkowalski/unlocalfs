import Foundation

struct MountCommand {
    private static let logMaxSize = "3M"
    private static let logMaxBackups = 2
    private static let readChunkStreams = 4
    private static let readChunkSize = "16M"
    private static let readBufferSize = "32M"
    private static let maxBufferMemory = "256M"
    private static let readChunkSizeLimit = "1G"
    private static let multiThreadWriteBufferSize = "4M"
    private static let jobExpiry = "5s"
    private static let jobExpiryCheck = "2s"

    let remote: RcloneRemote
    let paths: AppPaths

    var arguments: [String] {
        let connection = remote.connection
        var arguments = [
            "rcd", "--config", "/dev/null", "--cache-dir", paths.cache(connection).path,
            "--buffer-size", Self.readBufferSize, "--max-buffer-memory", Self.maxBufferMemory,
            "--transfers", "\(connection.transfers)", "--default-time", Date.now.ISO8601Format(),
            "--rc-no-auth", "--rc-job-expire-duration", Self.jobExpiry, "--rc-job-expire-interval", Self.jobExpiryCheck,
            "--rc-addr", "unix://\(paths.socket(connection).path)", "--log-level", "INFO",
            "--log-file", paths.log(connection).path, "--log-file-max-size", Self.logMaxSize, "--log-file-max-backups", "\(Self.logMaxBackups)",
        ]
        if connection.backend == .sftp {
            arguments += connection.multiThreadUploads
                ? ["--multi-thread-write-buffer-size", Self.multiThreadWriteBufferSize]
                : ["--multi-thread-streams", "1"]
        }
        if connection.bandwidthLimit > 0 { arguments += ["--bwlimit", "\(connection.bandwidthLimit)B"] }
        if connection.usesUploadTimes { arguments.append("--use-server-modtime") }
        return arguments
    }

    var environment: [String: String] {
        var environment = ["UNLOCALFS_VOLUME_NAME": remote.connection.name]
        environment["SSH_AUTH_SOCK"] = remote.agentSocket
        return environment
    }

    var mountParameters: [String: String] {
        let connection = remote.connection
        var parameters = [
            "fs": connection.driveTarget, "mountPoint": paths.mount(connection).path, "mountType": "nfsmount",
            "vfs_cache_mode": "full", "vfs_cache_max_size": "\(connection.cacheLimit)B", "vfs_cache_max_age": "off",
            "vfs_cache_min_free_space": connection.minimumFreeSpace > 0 ? "\(connection.minimumFreeSpace)B" : "off",
            "vfs_fast_fingerprint": "true",
        ]
        if connection.backend != .sftp {
            parameters["vfs_read_chunk_streams"] = "\(Self.readChunkStreams)"
            parameters["vfs_read_chunk_size"] = Self.readChunkSize
            parameters["vfs_read_chunk_size_limit"] = Self.readChunkSizeLimit
        }
        if connection.readOnly { parameters["read_only"] = "true" }
        return parameters
    }
}

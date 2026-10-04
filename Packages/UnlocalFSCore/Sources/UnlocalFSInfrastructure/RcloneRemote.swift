import Foundation
import UnlocalFSDomain

struct RcloneRemote {
    let connection: Connection
    let credentials: Credentials?
    var agentSocket: String?

    var type: String {
        switch connection.backend {
        case .s3Compatible: "s3"
        case .sftp: "sftp"
        case .gcs: "gcs"
        }
    }
    var exportName: String { "unlocalfs-\(type)" }
    var path: String {
        switch connection.backend {
        case .s3Compatible, .gcs: connection.folder.isEmpty ? connection.bucket : "\(connection.bucket)/\(connection.folder)"
        case .sftp: connection.sftp.remotePath
        }
    }
    var storage: String { ":\(type):\(path)" }
    var target: String { connection.encrypted ? ":crypt:" : storage }

    var options: [String: String] {
        switch connection.backend {
        case .s3Compatible: s3Options
        case .sftp: sftpOptions
        case .gcs: gcsOptions
        }
    }

    var environment: [String: String] {
        var environment = Dictionary(uniqueKeysWithValues: options.map { ("RCLONE_\(type.uppercased())_\($0.key.uppercased())", $0.value) })
        if let agentSocket { environment["SSH_AUTH_SOCK"] = agentSocket }
        if connection.encrypted {
            environment["RCLONE_CRYPT_REMOTE"] = storage
            environment["RCLONE_CRYPT_PASSWORD"] = credentials?.obscuredEncryptionPassword
        }
        return environment
    }

    private var s3Options: [String: String] {
        var options = [
            "provider": connection.provider.rawValue,
            "endpoint": connection.endpoint,
            "region": connection.region,
            "env_auth": "false",
            "directory_markers": "true",
            "no_check_bucket": "true"
        ]
        if let credentials {
            options["access_key_id"] = credentials.accessKey
            options["secret_access_key"] = credentials.secretKey
            options["session_token"] = credentials.sessionToken
        }
        return options
    }

    private var gcsOptions: [String: String] {
        var options = ["bucket_policy_only": "true", "no_check_bucket": "true", "directory_markers": "true"]
        options["service_account_credentials"] = credentials?.serviceAccountKey
        return options
    }

    private var sftpOptions: [String: String] {
        let sftp = connection.sftp
        var options = [
            "host": sftp.host, "port": "\(sftp.port)", "user": sftp.username,
            "shell_type": "none", "known_hosts_file": sftp.trustedHostsPath
        ]
        switch sftp.authentication {
        case .password:
            options["pass"] = credentials?.obscuredPassword
        case .privateKey:
            options["key_file"] = sftp.keyPath
            if let passphrase = credentials?.obscuredKeyPassphrase, !passphrase.isEmpty { options["key_file_pass"] = passphrase }
        case .agent:
            options["key_use_agent"] = "true"
        }
        return options
    }
}

extension SFTPSettings {
    var trustedHostsPath: String { trustedHostsFile.expandingTilde }
    var keyPath: String { keyFile.expandingTilde }
    var agentSocketPath: String { agentSocket.expandingTilde }
}

private extension String {
    var expandingTilde: String { (self as NSString).expandingTildeInPath }
}

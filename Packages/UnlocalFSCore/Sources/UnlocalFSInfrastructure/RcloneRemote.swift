import UnlocalFSDomain

struct RcloneRemote {
    let connection: Connection
    let credentials: Credentials?

    var path: String { connection.folder.isEmpty ? connection.bucket : "\(connection.bucket)/\(connection.folder)" }
    var storage: String { ":s3:\(path)" }
    var target: String { connection.encrypted ? ":crypt:" : storage }

    var s3Options: [String: String] {
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

    var environment: [String: String] {
        var environment = Dictionary(uniqueKeysWithValues: s3Options.map { ("RCLONE_S3_\($0.key.uppercased())", $0.value) })
        if connection.encrypted {
            environment["RCLONE_CRYPT_REMOTE"] = storage
            environment["RCLONE_CRYPT_PASSWORD"] = credentials?.obscuredEncryptionPassword
        }
        return environment
    }
}

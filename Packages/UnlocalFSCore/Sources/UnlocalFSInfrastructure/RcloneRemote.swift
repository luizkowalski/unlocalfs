import Foundation
import UnlocalFSDomain

struct RcloneRemote {
    let connection: Connection
    let credentials: Credentials?
    let knownHosts: URL
    let googleClient: GoogleClient
    var agentSocket: String?

    init(connection: Connection, credentials: Credentials?, knownHosts: URL, googleClient: GoogleClient, agentSocket: String? = nil) throws {
        if connection.usesGoogleSignIn, let credentials {
            try googleClient.requireConfigured()
            guard credentials.isSignedInToGoogle else { throw GoogleSignInRequired() }
        }
        self.connection = connection
        self.credentials = credentials
        self.knownHosts = knownHosts
        self.googleClient = googleClient
        self.agentSocket = agentSocket
    }

    var options: [String: String] {
        switch connection.backend {
        case .s3Compatible: s3Options
        case .sftp: sftpOptions
        case .gcs: gcsOptions
        }
    }

    var storageRemote: NamedRemote { NamedRemote(name: connection.storageRemoteName, type: connection.rcloneType, options: options) }

    var namedRemotes: [NamedRemote] {
        guard connection.encrypted else { return [storageRemote] }
        return [storageRemote, NamedRemote(name: Connection.cryptRemoteName, type: "crypt", options: cryptOptions)]
    }

    var environment: [String: String] {
        var environment: [String: String] = [:]
        for remote in namedRemotes {
            let prefix = "RCLONE_CONFIG_\(remote.name.uppercased())_"
            environment[prefix + "TYPE"] = remote.type
            for (key, value) in remote.parameters { environment[prefix + key.uppercased()] = value }
        }
        environment["SSH_AUTH_SOCK"] = agentSocket
        return environment
    }

    private var cryptOptions: [String: String] {
        var options = ["remote": connection.driveStorage, "filename_encryption": "standard", "directory_name_encryption": "true", "filename_encoding": "base32"]
        options["password"] = credentials?.obscuredEncryptionPassword
        return options
    }

    private var s3Options: [String: String] {
        var options = [
            "provider": connection.provider.rawValue,
            "endpoint": connection.endpoint,
            "region": connection.region,
            "env_auth": "false",
            "directory_markers": "true",
            "no_check_bucket": "true",
            "no_head": "true",
        ]
        if let credentials {
            options["access_key_id"] = credentials.accessKey
            options["secret_access_key"] = credentials.secretKey
            options["session_token"] = credentials.sessionToken
        }
        if connection.provider == .aws {
            let aws = connection.aws
            options["storage_class"] = aws.storageClass == .standard ? nil : aws.storageClass.rawValue
            options["server_side_encryption"] = aws.serverSideEncryption?.rawValue
            if aws.serverSideEncryption == .kms, !aws.kmsKeyID.isEmpty { options["sse_kms_key_id"] = aws.kmsKeyID }
        }
        return options
    }

    private var gcsOptions: [String: String] {
        var options = ["bucket_policy_only": "true", "no_check_bucket": "true", "directory_markers": "true"]
        guard let credentials else { return options }
        switch connection.gcs.authentication {
        case .serviceAccount:
            options["service_account_credentials"] = credentials.serviceAccountKey
        case .googleAccount:
            options["token"] = credentials.googleToken
            options["client_id"] = googleClient.id
            options["client_secret"] = googleClient.secret
            options["env_auth"] = "false"
            options["config_refresh_token"] = "false"
        }
        return options
    }

    private var sftpOptions: [String: String] {
        let sftp = connection.sftp
        var options = [
            "host": sftp.host, "port": "\(sftp.port)", "user": sftp.username,
            "shell_type": "none", "known_hosts_file": knownHosts.path, "idle_timeout": "3m", "multithread_upload": "true",
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

extension Connection {
    var rcloneType: String {
        switch backend {
        case .s3Compatible: "s3"
        case .sftp: "sftp"
        case .gcs: "gcs"
        }
    }

    var rclonePath: String {
        switch backend {
        case .s3Compatible, .gcs: bucketPath
        case .sftp: sftp.remotePath
        }
    }

    static let cryptRemoteName = "unlocalfs"
    var storageRemoteName: String { "unlocalfs-\(rcloneType)" }
    var driveStorage: String { "\(storageRemoteName):\(rclonePath)" }
    var driveTarget: String { encrypted ? "\(Self.cryptRemoteName):" : driveStorage }
}

struct NamedRemote: Encodable {
    private struct Options: Encodable {
        let nonInteractive = true
        let noObscure = true
    }

    let name: String
    let type: String
    let parameters: [String: String]
    private let opt = Options()

    init(name: String, type: String, options: [String: String]) {
        self.name = name
        self.type = type
        parameters = options.filter { !$0.value.isEmpty }
    }
}

extension SFTPSettings {
    var keyPath: String { keyFile.expandingTilde }
    var agentSocketPath: String { agentSocket.expandingTilde }
}

private extension String {
    var expandingTilde: String { (self as NSString).expandingTildeInPath }
}

import Foundation

public enum SFTPAuthentication: String, Codable, CaseIterable, Identifiable, Sendable {
    case password = "Password"
    case privateKey = "PrivateKey"
    case agent = "Agent"

    public var id: Self { self }

    public var title: String {
        switch self {
        case .password: "Password"
        case .privateKey: "Private key"
        case .agent: "SSH agent"
        }
    }
}

public struct SFTPSettings: Codable, Equatable, Sendable {
    public static let defaultTrustedHostsFile = "~/.ssh/known_hosts"

    public var host = ""
    public var port = 22
    public var username = ""
    public var remotePath = ""
    public var authentication = SFTPAuthentication.password
    public var keyFile = ""
    public var trustedHostsFile = Self.defaultTrustedHostsFile
    public var agentSocket = ""

    public init() {}

    public func validate() -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        let separators = CharacterSet.whitespacesAndNewlines.union(.controlCharacters)
        result.check(
            !host.isBlank && host.rangeOfCharacter(from: separators) == nil,
            field: .host, message: "Enter the server's host name or IP address."
        )
        result.check((1...65_535).contains(port), field: .port, message: "Enter a port from 1 to 65535.")
        result.check(
            !username.isBlank && username.rangeOfCharacter(from: .controlCharacters) == nil,
            field: .username, message: "Enter the username for this server."
        )
        result.check(
            remotePath.rangeOfCharacter(from: .controlCharacters) == nil,
            field: .remotePath, message: "Enter a folder path without control characters, or leave it empty for your home folder."
        )
        if authentication == .privateKey {
            result.check(
                Self.isFullPath(keyFile), field: .keyFile,
                message: "Enter the full path of your private key file, for example ~/.ssh/id_ed25519."
            )
        }
        result.check(
            Self.isFullPath(trustedHostsFile), field: .trustedHosts,
            message: "Enter the full path of your trusted-hosts file, for example \(Self.defaultTrustedHostsFile)."
        )
        return result
    }

    private static func isFullPath(_ path: String) -> Bool {
        (path.hasPrefix("/") || path.hasPrefix("~/")) && path.rangeOfCharacter(from: .controlCharacters) == nil
    }
}

extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

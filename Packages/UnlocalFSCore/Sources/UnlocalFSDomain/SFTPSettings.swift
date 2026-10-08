import Foundation

public enum SFTPAuthentication: String, Codable, CaseIterable, Identifiable, Sendable {
    case password = "Password"
    case privateKey = "PrivateKey"
    case agent = "Agent"

    public var id: Self { self }

    public var title: String {
        switch self {
        case .password: String(localized: .password)
        case .privateKey: String(localized: .privateKey)
        case .agent: String(localized: .authenticationAgent)
        }
    }
}

public struct SFTPSettings: Codable, Equatable, Sendable {
    public var host = ""
    public var port = 22
    public var username = ""
    public var remotePath = ""
    public var authentication = SFTPAuthentication.password
    public var keyFile = ""
    public var agentSocket = ""

    public init() {}

    public func validate() -> ValidationResult<ConnectionField> {
        var result = ValidationResult<ConnectionField>()
        let separators = CharacterSet.whitespacesAndNewlines.union(.controlCharacters)
        result.check(
            !host.isBlank && host.rangeOfCharacter(from: separators) == nil,
            field: .host, message: String(localized: .hostMissing)
        )
        result.check((1...65_535).contains(port), field: .port, message: String(localized: .portOutOfRange))
        result.check(
            !username.isBlank && username.rangeOfCharacter(from: .controlCharacters) == nil,
            field: .username, message: String(localized: .usernameMissing)
        )
        result.check(
            remotePath.rangeOfCharacter(from: .controlCharacters) == nil,
            field: .remotePath, message: String(localized: .remotePathInvalid)
        )
        if authentication == .privateKey {
            result.check(
                Self.isFullPath(keyFile), field: .keyFile,
                message: String(localized: .keyFileNotFullPath)
            )
        }
        return result
    }

    private static func isFullPath(_ path: String) -> Bool {
        (path.hasPrefix("/") || path.hasPrefix("~/")) && path.rangeOfCharacter(from: .controlCharacters) == nil
    }
}

extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

import Foundation

public enum GCSAuthentication: String, Codable, CaseIterable, Identifiable, Sendable {
    case googleAccount = "GoogleAccount"
    case serviceAccount = "ServiceAccount"

    public var id: Self { self }

    public var title: String {
        switch self {
        case .googleAccount: String(localized: .fieldGoogleAccount)
        case .serviceAccount: String(localized: .fieldServiceAccountKey)
        }
    }
}

public struct GCSSettings: Codable, Equatable, Sendable {
    public var authentication: GCSAuthentication

    public init(authentication: GCSAuthentication = .googleAccount) {
        self.authentication = authentication
    }
}

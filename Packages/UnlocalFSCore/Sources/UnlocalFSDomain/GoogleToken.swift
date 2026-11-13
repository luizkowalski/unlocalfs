import Foundation

public struct GoogleToken: Equatable, Sendable {
    public let json: String
    public let accessToken: String
    public let refreshToken: String

    public init?(json: String) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let fields = try? decoder.decode(Fields.self, from: Data(json.utf8)),
              let refreshToken = fields.refreshToken, !refreshToken.isEmpty,
              fields.expiry.map(Self.isDate) ?? true
        else { return nil }
        self.json = json
        accessToken = fields.accessToken ?? ""
        self.refreshToken = refreshToken
    }

    private struct Fields: Decodable {
        let accessToken: String?
        let refreshToken: String?
        let expiry: String?
    }

    private static func isDate(_ text: String) -> Bool {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return ISO8601DateFormatter().date(from: text) != nil || fractional.date(from: text) != nil
    }
}

public struct GoogleSignInRequired: LocalizedError, Sendable {
    public init() {}

    public var errorDescription: String? { String(localized: .googleSignInRequired) }
}

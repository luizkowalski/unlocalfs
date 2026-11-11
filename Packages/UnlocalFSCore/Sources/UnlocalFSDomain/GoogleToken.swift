import Foundation

public struct GoogleToken: Equatable, Sendable {
    public let json: String
    public let accessToken: String
    public let refreshToken: String

    public init?(json: String) {
        guard let fields = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any],
              let refreshToken = fields["refresh_token"] as? String, !refreshToken.isEmpty
        else { return nil }
        self.json = json
        accessToken = fields["access_token"] as? String ?? ""
        self.refreshToken = refreshToken
    }
}

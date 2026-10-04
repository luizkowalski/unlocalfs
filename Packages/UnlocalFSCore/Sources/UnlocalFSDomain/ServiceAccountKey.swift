import Foundation

public struct ServiceAccountKey: Equatable, Sendable {
    public let email: String
    public let json: String

    public init(importing data: Data) throws {
        guard let fields = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              fields["type"] as? String == "service_account",
              let email = fields["client_email"] as? String, !email.isEmpty,
              let privateKey = fields["private_key"] as? String, !privateKey.isEmpty,
              let compact = try? JSONSerialization.data(withJSONObject: fields, options: .withoutEscapingSlashes) else {
            throw AppError(L10n.notAServiceAccountKey)
        }
        self.email = email
        json = String(decoding: compact, as: UTF8.self)
    }

    public init?(json: String) {
        try? self.init(importing: Data(json.utf8))
    }
}

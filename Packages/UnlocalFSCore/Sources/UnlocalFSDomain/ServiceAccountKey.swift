import Foundation

public struct ServiceAccountKey: Equatable, Sendable {
    public let email: String
    public let json: String

    private struct Fields: Decodable {
        let type: String
        let clientEmail: String
        let privateKey: String
    }

    public init(importing data: Data) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let fields = try? decoder.decode(Fields.self, from: data),
              fields.type == "service_account", !fields.clientEmail.isEmpty, !fields.privateKey.isEmpty,
              let object = try? JSONSerialization.jsonObject(with: data),
              let compact = try? JSONSerialization.data(withJSONObject: object, options: .withoutEscapingSlashes) else {
            throw AppError("Not a service-account key. Choose the JSON key you downloaded from Google Cloud.")
        }
        email = fields.clientEmail
        json = String(decoding: compact, as: UTF8.self)
    }

    public init?(json: String) {
        try? self.init(importing: Data(json.utf8))
    }
}

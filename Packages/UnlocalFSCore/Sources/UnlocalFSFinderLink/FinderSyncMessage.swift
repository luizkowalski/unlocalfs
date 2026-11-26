import Foundation

@usableFromInline enum FinderSyncMessage {
    static let version = 2
    static let changedNotification = "net.luizkowalski.unlocalfs.finder.changed"
    @usableFromInline static var portName: String { Bundle.main.object(forInfoDictionaryKey: "FinderPortName") as? String ?? "" }

    private struct Envelope<Body: Codable>: Codable {
        var version = FinderSyncMessage.version
        let body: Body
    }

    struct UnsupportedVersion: Error {}

    static func encode(_ body: some Codable) throws -> Data {
        try JSONEncoder().encode(Envelope(body: body))
    }

    static func decode<Body: Codable>(_: Body.Type, from data: Data) throws -> Body {
        let envelope = try JSONDecoder().decode(Envelope<Body>.self, from: data)
        guard envelope.version == version else { throw UnsupportedVersion() }
        return envelope.body
    }
}

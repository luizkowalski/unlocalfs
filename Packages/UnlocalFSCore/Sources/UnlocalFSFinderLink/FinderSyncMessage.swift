import Foundation

public enum FinderSyncMessage {
    public static let version = 1
    public static let changedNotification = "net.luizkowalski.unlocalfs.finder.changed"
    public static var portName: String { Bundle.main.object(forInfoDictionaryKey: "FinderPortName") as? String ?? "" }

    private struct Envelope<Body: Codable>: Codable {
        var version = FinderSyncMessage.version
        let body: Body
    }

    public struct UnsupportedVersion: Error {}

    public static func encode(_ body: some Codable) throws -> Data {
        try JSONEncoder().encode(Envelope(body: body))
    }

    public static func decode<Body: Codable>(_: Body.Type, from data: Data) throws -> Body {
        let envelope = try JSONDecoder().decode(Envelope<Body>.self, from: data)
        guard envelope.version == version else { throw UnsupportedVersion() }
        return envelope.body
    }
}

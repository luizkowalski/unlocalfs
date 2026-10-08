import Foundation

public struct ServerTrustChallenge: LocalizedError, Identifiable, Sendable {
    public let id: UUID
    public let host: String
    public let port: Int
    public let fingerprints: String
    public let keyChanged: Bool

    public init(id: UUID, host: String, port: Int, fingerprints: String, keyChanged: Bool) {
        self.id = id
        self.host = host
        self.port = port
        self.fingerprints = fingerprints
        self.keyChanged = keyChanged
    }

    public var server: String { "\(host):\(port)" }
    public var errorDescription: String? {
        keyChanged
            ? String(localized: .serverKeyChanged(server, fingerprints))
            : String(localized: .serverKeyNeedsTrust(server, fingerprints))
    }
}

import Foundation

public struct FinderSnapshot: Codable, Hashable, Sendable {
    public struct Drive: Codable, Hashable, Sendable {
        public let mount: URL
        public let uploads: [String: UploadState]

        public init(mount: URL, uploads: [String: UploadState]) {
            self.mount = mount
            self.uploads = uploads
        }
    }

    public let drives: [Drive]

    public init(drives: [Drive]) {
        self.drives = drives
    }

    public var version: Int { hashValue }

    public var watchedFolders: Set<URL> {
        Set(drives.flatMap { [$0.mount, $0.mount.deletingLastPathComponent()] })
    }
}

public struct FinderItem: Codable, Hashable, Sendable {
    public let url: URL
    public let isFolder: Bool

    public init(url: URL, isFolder: Bool) {
        self.url = url
        self.isFolder = isFolder
    }
}

public enum FinderCommand: Codable, Hashable, Sendable {
    case copyShareLink(ShareLinkExpiry)
    case duplicateOnServer
}

public struct FinderMenuItem: Codable, Hashable, Sendable {
    public let title: String
    public let command: FinderCommand

    public init(title: String, command: FinderCommand) {
        self.title = title
        self.command = command
    }
}

public enum FinderSyncRequest: Codable, Hashable, Sendable {
    case snapshot(since: Int?)
    case menu([FinderItem])
    case run(FinderCommand, files: [URL])
}

public enum FinderSyncReply: Codable, Hashable, Sendable {
    case unchanged
    case snapshot(FinderSnapshot, version: Int)
    case menu([FinderMenuItem])
    case accepted
    case failed
}

public enum FinderSyncMessage {
    public static let version = 1
    public static let changedNotification = "net.luizkowalski.unlocalfs.finder.changed"
    public static var portName: String { Bundle.main.object(forInfoDictionaryKey: "FinderPortName") as? String ?? "" }

    private struct Envelope<Body: Codable>: Codable {
        var version = FinderSyncMessage.version
        let body: Body
    }

    private struct Header: Decodable {
        let version: Int
    }

    public struct UnsupportedVersion: Error {}

    public static func encode(_ body: some Codable) throws -> Data {
        try JSONEncoder().encode(Envelope(body: body))
    }

    public static func decode<Body: Codable>(_: Body.Type, from data: Data) throws -> Body {
        guard try JSONDecoder().decode(Header.self, from: data).version == version else { throw UnsupportedVersion() }
        return try JSONDecoder().decode(Envelope<Body>.self, from: data).body
    }
}

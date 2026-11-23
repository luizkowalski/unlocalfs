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

    public var watchedFolders: Set<URL> {
        Set(drives.flatMap { [$0.mount, $0.mount.deletingLastPathComponent()] })
    }
}

public enum FinderCommand: Codable, Hashable, Sendable {
    case copyShareLink(ShareLinkExpiry)
    case duplicateOnServer
    case showVersions
    case showRecentlyDeleted
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
    case menu([URL])
    case run(FinderCommand, files: [URL])
}

public enum FinderSyncReply: Codable, Hashable, Sendable {
    case unchanged(checkedAt: [URL: Date])
    case snapshot(FinderSnapshot, version: Int, checkedAt: [URL: Date])
    case menu([FinderMenuItem])
    case accepted
    case windowOpened
    case failed
}

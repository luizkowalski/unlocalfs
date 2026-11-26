import Foundation

public struct VersionsTarget: Identifiable, Sendable {
    public let connection: Connection
    public let path: String
    public let isFolder: Bool

    public init(connection: Connection, path: String, isFolder: Bool) {
        self.connection = connection
        self.path = path
        self.isFolder = isFolder
    }

    public var id: String { "\(connection.id.uuidString)/\(path)" }

    public var name: String { path.isEmpty ? connection.name : (path as NSString).lastPathComponent }

    public var offersRestoreAsCopy: Bool { !isFolder }

    var listedFolder: String { isFolder ? path : (path as NSString).deletingLastPathComponent }

    func versions(in listing: VersionListing) -> [FileVersion] {
        isFolder ? listing.deletedFiles : listing.history(of: path)
    }
}

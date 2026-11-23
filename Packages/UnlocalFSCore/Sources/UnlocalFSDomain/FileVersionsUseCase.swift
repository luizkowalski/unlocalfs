import Foundation

public struct FileVersions: Sendable {
    public let versioning: BucketVersioning
    public let versions: [FileVersion]
}

public struct FileVersionsUseCase: Sendable {
    private let drives: any DriveGateway

    public init(drives: any DriveGateway) {
        self.drives = drives
    }

    public func load(_ path: String, isFolder: Bool, in connection: Connection) async throws -> FileVersions {
        if let refusal = connection.versionsRefusal { throw AppError(refusal) }
        let versioning = await drives.versioning(of: connection)
        guard versioning != .off else { return FileVersions(versioning: versioning, versions: []) }
        let folder = isFolder ? path : (path as NSString).deletingLastPathComponent
        let listing = try await VersionListing(drives.versions(in: folder, of: connection))
        return FileVersions(versioning: versioning, versions: isFolder ? listing.deletedFiles : listing.history(of: path))
    }

    public func restore(_ version: FileVersion, asCopy: Bool, in connection: Connection) async throws -> String {
        if let refusal = connection.versionsRefusal ?? connection.serverCopyRefusal { throw AppError(refusal) }
        return try await drives.restore(version, asCopy: asCopy, in: connection)
    }
}

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

    public func load(_ target: VersionsTarget) async throws -> FileVersions {
        if let refusal = target.connection.versionsRefusal { throw AppError(refusal) }
        let versioning = await drives.versioning(of: target.connection)
        guard versioning != .off else { return FileVersions(versioning: versioning, versions: []) }
        let listing = try await VersionListing(drives.versions(in: target.listedFolder, of: target.connection))
        return FileVersions(versioning: versioning, versions: target.versions(in: listing))
    }

    public func restore(_ version: FileVersion, asCopy: Bool, in connection: Connection) async throws -> String {
        if let refusal = connection.versionsRefusal ?? connection.serverCopyRefusal { throw AppError(refusal) }
        return try await drives.restore(version, asCopy: asCopy, in: connection)
    }

    public func preview(_ version: FileVersion, in connection: Connection) async throws -> URL {
        try await drives.preview(version, in: connection)
    }

    public func discardPreview(_ file: URL) {
        drives.discardPreview(file)
    }
}

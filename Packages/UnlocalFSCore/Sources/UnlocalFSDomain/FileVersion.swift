import Foundation

public enum BucketVersioning: Sendable {
    case enabled, suspended, off, unknown
}

public struct FileVersion: Identifiable, Sendable {
    public let path: String
    public let filePath: String
    public let size: Int64
    public let savedAt: Date
    public let isCurrent: Bool

    public var id: String { path }
    public var name: String { (filePath as NSString).lastPathComponent }

    public init(path: String, size: Int64, savedAt: Date) {
        self.path = path
        self.size = size
        self.savedAt = savedAt
        let folder = (path as NSString).deletingLastPathComponent
        let fileName = VersionName(of: (path as NSString).lastPathComponent).fileName
        filePath = fileName.map { (folder as NSString).appendingPathComponent($0) } ?? path
        isCurrent = fileName == nil
    }
}

public struct VersionListing: Sendable {
    private let versions: [FileVersion]

    public init(_ versions: [FileVersion]) {
        self.versions = versions.sorted { $0.savedAt > $1.savedAt }
    }

    public func history(of filePath: String) -> [FileVersion] {
        let history = versions.filter { $0.filePath == filePath }
        return history.filter(\.isCurrent) + history.filter { !$0.isCurrent }
    }

    public var deletedFiles: [FileVersion] {
        let current = Set(versions.filter(\.isCurrent).map(\.filePath))
        var seen: Set<String> = []
        return versions.filter { !current.contains($0.filePath) && seen.insert($0.filePath).inserted }
    }
}

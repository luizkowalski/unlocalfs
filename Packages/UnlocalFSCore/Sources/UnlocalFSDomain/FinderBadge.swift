import Foundation

public enum FinderBadge: CaseIterable, Comparable, Sendable {
    case uploaded, uploading, failed

    init(_ state: UploadState) {
        self = state == .failed ? .failed : .uploading
    }
}

public struct FinderBadges: Sendable {
    private struct Drive {
        let root: [String]
        let badges: [String: FinderBadge]
    }

    private let drives: [Drive]

    public init(_ snapshot: FinderSnapshot) {
        drives = snapshot.drives.map { Drive(root: $0.mount.standardizedFileURL.pathComponents, badges: Self.rollUp($0.uploads)) }
    }

    public func badge(for url: URL) -> FinderBadge? {
        let components = url.standardizedFileURL.pathComponents
        guard let drive = drives.first(where: { components.starts(with: $0.root) }) else { return nil }
        return drive.badges[components.dropFirst(drive.root.count).joined(separator: "/"), default: .uploaded]
    }

    private static func rollUp(_ uploads: [String: UploadState]) -> [String: FinderBadge] {
        var badges: [String: FinderBadge] = [:]
        for (path, state) in uploads {
            let components = path.split(separator: "/")
            for count in 0 ... components.count {
                let folder = components.prefix(count).joined(separator: "/")
                badges[folder] = max(badges[folder, default: .uploaded], FinderBadge(state))
            }
        }
        return badges
    }
}

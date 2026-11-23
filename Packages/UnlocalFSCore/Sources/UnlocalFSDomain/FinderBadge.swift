import Foundation

public enum FinderBadge: CaseIterable, Comparable, Sendable {
    case uploaded, uploading, failed

    init(_ state: UploadState) {
        self = state == .failed ? .failed : .uploading
    }
}

public struct FinderBadges: Sendable {
    private struct Drive {
        let mount: URL
        let badges: [String: FinderBadge]
    }

    private let drives: [Drive]

    public init(_ snapshot: FinderSnapshot) {
        drives = snapshot.drives.map { Drive(mount: $0.mount, badges: Self.rollUp($0.uploads)) }
    }

    public func badge(for url: URL) -> FinderBadge? {
        for drive in drives {
            if let path = url.path(inside: drive.mount) { return drive.badges[path, default: .uploaded] }
        }
        return nil
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

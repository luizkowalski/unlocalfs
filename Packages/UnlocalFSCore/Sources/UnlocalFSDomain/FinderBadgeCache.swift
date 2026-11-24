import Foundation

public struct FinderUpdate: Equatable, Sendable {
    public let badges: [URL: FinderBadge?]
    public let watchedFolders: Set<URL>?
    public let pullAgainAfter: TimeInterval?
}

public struct FinderBadgeCache: Sendable {
    public private(set) var version: Int?
    private var badges = FinderBadges(FinderSnapshot(drives: []))
    private var watched: Set<URL> = []
    private var known: [String: Set<URL>] = [:]
    private var firstSeen: [URL: Date] = [:]

    public init() {}

    private var allKnown: Set<URL> { known.values.reduce(into: []) { $0.formUnion($1) } }

    public func badge(for url: URL) -> FinderBadge? {
        guard let badge = badges.badge(for: url) else { return nil }
        return firstSeen[url] == nil ? badge : .checking
    }

    public mutating func see(_ url: URL, at date: Date) -> Bool {
        guard known[url.deletingLastPathComponent().path, default: []].insert(url).inserted else { return false }
        firstSeen[url] = date
        return true
    }

    public mutating func forget(folder: URL) {
        for url in known.removeValue(forKey: folder.path) ?? [] {
            firstSeen[url] = nil
        }
    }

    public mutating func receive(_ reply: FinderSyncReply?) -> FinderUpdate {
        switch reply {
        case let .unchanged(checkedAt):
            let ready = confirm(checkedAt: checkedAt)
            return update(showing: ready, watching: nil)
        case let .snapshot(snapshot, version, checkedAt):
            let folders = snapshot.watchedFolders
            let foldersChanged = folders != watched
            badges = FinderBadges(snapshot)
            self.version = version
            watched = folders
            _ = confirm(checkedAt: checkedAt)
            return update(showing: allKnown.subtracting(firstSeen.keys), watching: foldersChanged ? folders : nil)
        case nil:
            return FinderUpdate(badges: [:], watchedFolders: nil, pullAgainAfter: 3)
        default:
            let cleared = allKnown
            let wasWatching = !watched.isEmpty
            self = FinderBadgeCache()
            return FinderUpdate(badges: Dictionary(uniqueKeysWithValues: cleared.map { ($0, nil) }), watchedFolders: wasWatching ? [] : nil, pullAgainAfter: nil)
        }
    }

    private mutating func confirm(checkedAt checks: [URL: Date]) -> Set<URL> {
        let ready = firstSeen.filter { url, seen in
            guard let checked = checks.first(where: { url.path(inside: $0.key) != nil })?.value else { return true }
            return seen < checked
        }.keys
        for url in ready {
            firstSeen[url] = nil
        }
        return Set(ready)
    }

    private func update(showing urls: Set<URL>, watching folders: Set<URL>?) -> FinderUpdate {
        FinderUpdate(
            badges: Dictionary(uniqueKeysWithValues: urls.map { ($0, badge(for: $0)) }), watchedFolders: folders,
            pullAgainAfter: firstSeen.isEmpty ? nil : 0.5,
        )
    }
}

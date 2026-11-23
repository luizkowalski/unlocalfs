import Foundation

public struct FinderBadgeCache: Sendable {
    public private(set) var version: Int?
    public private(set) var badges = FinderBadges(FinderSnapshot(drives: []))
    private var watched: Set<URL> = []
    private var known: [String: Set<URL>] = [:]
    private var firstSeen: [URL: Date] = [:]

    public init() {}

    private var allKnown: Set<URL> { known.values.reduce(into: []) { $0.formUnion($1) } }
    public var isWaiting: Bool { !firstSeen.isEmpty }

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

    public mutating func confirm(checkedAt checks: [URL: Date]) -> Set<URL> {
        let ready = firstSeen.filter { url, seen in
            guard let checked = checks.first(where: { url.path(inside: $0.key) != nil })?.value else { return true }
            return seen < checked
        }.keys
        for url in ready {
            firstSeen[url] = nil
        }
        return Set(ready)
    }

    public mutating func apply(_ badges: FinderBadges, version: Int, watching folders: Set<URL>, checkedAt: [URL: Date]) -> (foldersChanged: Bool, ready: Set<URL>) {
        let foldersChanged = watched != folders
        self.badges = badges
        self.version = version
        watched = folders
        _ = confirm(checkedAt: checkedAt)
        return (foldersChanged, allKnown.subtracting(firstSeen.keys))
    }

    public mutating func reset() -> (known: Set<URL>, watched: Set<URL>) {
        defer { self = FinderBadgeCache() }
        return (allKnown, watched)
    }
}

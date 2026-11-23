import Cocoa
import FinderSync
import notify
import Synchronization
import UnlocalFSDomain
import UnlocalFSFinderLink

final class FinderSync: FIFinderSync, @unchecked Sendable {
    private let cache = Mutex(FinderBadgeCache())
    private let menuItems = Mutex<[FinderMenuItem]>([])
    private let queue = DispatchQueue(label: "net.luizkowalski.unlocalfs.finder")
    private let pulls: DispatchSourceUserDataOr
    private let fallback: DispatchSourceTimer
    private var controller: FIFinderSyncController { .default() }

    override init() {
        pulls = DispatchSource.makeUserDataOrSource(queue: queue)
        fallback = DispatchSource.makeTimerSource(queue: queue)
        super.init()
        controller.directoryURLs = []
        for badge in FinderBadge.allCases {
            controller.setBadgeImage(badge.image, label: badge.label, forBadgeIdentifier: badge.identifier)
        }
        pulls.setEventHandler { [weak self] in self?.pull() }
        pulls.activate()
        var token: Int32 = 0
        notify_register_dispatch(FinderSyncMessage.changedNotification, &token, queue) { [weak self] _ in self?.schedulePull() }
        fallback.schedule(deadline: .now(), repeating: 30)
        fallback.setEventHandler { [weak self] in self?.schedulePull() }
        fallback.resume()
    }

    override func requestBadgeIdentifier(for url: URL) {
        if cache.withLock({ $0.see(url, at: .now) }) {
            schedulePull()
        } else {
            show(cache.withLock { $0.badges }, on: [url])
        }
    }

    override func endObservingDirectory(at url: URL) {
        cache.withLock { $0.forget(folder: url) }
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems, let urls = controller.selectedItemURLs(), !urls.isEmpty,
              case let .menu(items) = FinderSyncClient()?.send(.menu(urls.map { FinderItem(url: $0, isFolder: $0.hasDirectoryPath) })), !items.isEmpty
        else { return nil }
        menuItems.withLock { $0 = items }
        let menu = NSMenu(title: "")
        for (index, item) in items.enumerated() {
            let menuItem = NSMenuItem(title: item.title, action: #selector(run(_:)), keyEquivalent: "")
            menuItem.tag = index
            menu.addItem(menuItem)
        }
        return menu
    }

    @objc private func run(_ sender: NSMenuItem) {
        guard let item = menuItems.withLock({ $0.indices.contains(sender.tag) ? $0[sender.tag] : nil }),
              let urls = controller.selectedItemURLs(), !urls.isEmpty else { return }
        _ = FinderSyncClient()?.send(.run(item.command, files: urls))
    }

    private func schedulePull() {
        pulls.or(data: 1)
    }

    private func schedulePullAgain() {
        queue.asyncAfter(deadline: .now() + 3) { [weak self] in self?.schedulePull() }
    }

    private func pull() {
        guard let app = FinderSyncClient() else { return clear() }
        switch app.send(.snapshot(since: cache.withLock { $0.version }), timeout: 2) {
        case let .unchanged(checkedAt):
            let (badges, ready) = cache.withLock { ($0.badges, $0.confirm(checkedAt: checkedAt)) }
            show(badges, on: ready)
        case let .snapshot(snapshot, version, checkedAt):
            let badges = FinderBadges(snapshot)
            let watched = snapshot.watchedFolders
            let result = cache.withLock { $0.apply(badges, version: version, watching: watched, checkedAt: checkedAt) }
            if result.foldersChanged { controller.directoryURLs = watched }
            show(badges, on: result.ready)
        case nil:
            return schedulePullAgain()
        default:
            return clear()
        }
        if cache.withLock({ $0.isWaiting }) { schedulePullAgain() }
    }

    private func clear() {
        let cleared = cache.withLock { $0.reset() }
        for url in cleared.known {
            controller.setBadgeIdentifier("", for: url)
        }
        if !cleared.watched.isEmpty { controller.directoryURLs = [] }
    }

    private func show(_ badges: FinderBadges, on urls: Set<URL>) {
        for url in urls {
            controller.setBadgeIdentifier(badges.badge(for: url)?.identifier ?? "", for: url)
        }
    }
}

private extension FinderBadge {
    var identifier: String { "\(self)" }

    var image: NSImage {
        let (symbol, color): (String, NSColor) = switch self {
        case .uploaded: ("checkmark.circle.fill", .systemGreen)
        case .uploading: ("arrow.up.circle.fill", .systemBlue)
        case .failed: ("exclamationmark.circle.fill", .systemRed)
        }
        return NSImage(systemSymbolName: symbol, accessibilityDescription: label)!
            .withSymbolConfiguration(NSImage.SymbolConfiguration(paletteColors: [.white, color]))!
    }

    var label: String {
        switch self {
        case .uploaded: String(localized: "Uploaded")
        case .uploading: String(localized: "Uploading")
        case .failed: String(localized: "Upload failed")
        }
    }
}

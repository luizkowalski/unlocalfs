import Cocoa
import FinderSync
import Synchronization
import UnlocalFSDomain
import UnlocalFSFinderLink

final class FinderSync: FIFinderSync, @unchecked Sendable {
    private let cache = Mutex(FinderBadgeCache())
    private let menuItems = Mutex<(items: [FinderMenuItem], urls: [URL])>(([], []))
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
        FinderSyncClient.observeChanges(on: queue) { [weak self] in self?.schedulePull() }
        fallback.schedule(deadline: .now(), repeating: 30)
        fallback.setEventHandler { [weak self] in self?.schedulePull() }
        fallback.resume()
    }

    override func requestBadgeIdentifier(for url: URL) {
        let isNew = cache.withLock { $0.see(url, at: .now) }
        show([url])
        if isNew { schedulePull() }
    }

    override func endObservingDirectory(at url: URL) {
        cache.withLock { $0.forget(folder: url) }
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let urls: [URL] = switch menuKind {
        case .contextualMenuForItems: controller.selectedItemURLs() ?? []
        case .contextualMenuForContainer: controller.targetedURL().map { [URL(filePath: $0.path(percentEncoded: false), directoryHint: .isDirectory)] } ?? []
        default: []
        }
        guard !urls.isEmpty, case let .menu(items) = FinderSyncClient()?.send(.menu(urls)), !items.isEmpty else { return nil }
        menuItems.withLock { $0 = (items, urls) }
        let menu = NSMenu(title: "")
        for (index, item) in items.enumerated() {
            let menuItem = NSMenuItem(title: item.title, action: #selector(run(_:)), keyEquivalent: "")
            menuItem.tag = index
            menu.addItem(menuItem)
        }
        return menu
    }

    @objc private func run(_ sender: NSMenuItem) {
        let (items, urls) = menuItems.withLock { $0 }
        guard items.indices.contains(sender.tag) else { return }
        let command = items[sender.tag].command
        guard FinderSyncClient()?.send(.run(command, files: urls)) == .accepted, command.opensWindow else { return }
        let app = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        NSWorkspace.shared.openApplication(at: app, configuration: NSWorkspace.OpenConfiguration())
    }

    private func schedulePull() {
        pulls.or(data: 1)
    }

    private func schedulePullAgain(after delay: TimeInterval) {
        fallback.schedule(deadline: .now() + delay, repeating: 30)
    }

    private func pull() {
        guard let app = FinderSyncClient() else { return clear() }
        switch app.send(.snapshot(since: cache.withLock { $0.version }), timeout: 2) {
        case let .unchanged(checkedAt):
            show(cache.withLock { $0.confirm(checkedAt: checkedAt) })
        case let .snapshot(snapshot, version, checkedAt):
            let badges = FinderBadges(snapshot)
            let watched = snapshot.watchedFolders
            let result = cache.withLock { $0.apply(badges, version: version, watching: watched, checkedAt: checkedAt) }
            if result.foldersChanged { controller.directoryURLs = watched }
            show(result.ready)
        case nil:
            return schedulePullAgain(after: 3)
        default:
            return clear()
        }
        if cache.withLock({ $0.isWaiting }) { schedulePullAgain(after: 0.5) }
    }

    private func clear() {
        let cleared = cache.withLock { $0.reset() }
        for url in cleared.known {
            controller.setBadgeIdentifier("", for: url)
        }
        if !cleared.watched.isEmpty { controller.directoryURLs = [] }
    }

    private func show(_ urls: Set<URL>) {
        let badges = cache.withLock { cache in urls.map { ($0, cache.badge(for: $0)) } }
        for (url, badge) in badges {
            controller.setBadgeIdentifier(badge?.identifier ?? "", for: url)
        }
    }
}

private extension FinderBadge {
    var identifier: String { "\(self)" }

    var image: NSImage {
        let (symbol, color): (String, NSColor) = switch self {
        case .checking: ("ellipsis.circle.fill", .systemGray)
        case .uploaded: ("checkmark.circle.fill", .systemGreen)
        case .uploading: ("arrow.up.circle.fill", .systemBlue)
        case .failed: ("exclamationmark.circle.fill", .systemRed)
        }
        return NSImage(systemSymbolName: symbol, accessibilityDescription: label)!
            .withSymbolConfiguration(NSImage.SymbolConfiguration(paletteColors: [.white, color]))!
    }

    var label: String {
        switch self {
        case .checking: String(localized: "Checking")
        case .uploaded: String(localized: "Uploaded")
        case .uploading: String(localized: "Uploading")
        case .failed: String(localized: "Upload failed")
        }
    }
}

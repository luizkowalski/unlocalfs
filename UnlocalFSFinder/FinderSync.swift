import Cocoa
import FinderSync
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
        FinderSyncClient.observeChanges(on: queue) { [weak self] in self?.schedulePull() }
        fallback.schedule(deadline: .now(), repeating: 30)
        fallback.setEventHandler { [weak self] in self?.schedulePull() }
        fallback.resume()
    }

    override func requestBadgeIdentifier(for url: URL) {
        let (isNew, badge) = cache.withLock { ($0.see(url, at: .now), $0.badge(for: url)) }
        controller.setBadgeIdentifier(badge?.identifier ?? "", for: url)
        if isNew { schedulePull() }
    }

    override func endObservingDirectory(at url: URL) {
        cache.withLock { $0.forget(folder: url) }
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems, let urls = controller.selectedItemURLs(), !urls.isEmpty,
              case let .menu(items) = FinderSyncClient()?.send(.menu(urls)), !items.isEmpty
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

    private func pull() {
        let version = cache.withLock { $0.version }
        let reply: FinderSyncReply? = if let app = FinderSyncClient() { app.send(.snapshot(since: version), timeout: 2) } else { .failed }
        let update = cache.withLock { $0.receive(reply) }
        if let folders = update.watchedFolders { controller.directoryURLs = folders }
        for (url, badge) in update.badges {
            controller.setBadgeIdentifier(badge?.identifier ?? "", for: url)
        }
        if let delay = update.pullAgainAfter {
            queue.asyncAfter(deadline: .now() + delay) { [weak self] in self?.schedulePull() }
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

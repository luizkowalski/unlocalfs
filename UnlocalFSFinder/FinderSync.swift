import Cocoa
import FinderSync
import notify
import Synchronization
import UnlocalFSDomain

final class FinderSync: FIFinderSync, @unchecked Sendable {
    private struct State {
        var version: Int?
        var badges = FinderBadges(FinderSnapshot(drives: []))
        var watched: Set<URL> = []
        var known: [String: Set<URL>] = [:]
        var unbadged: Set<URL> = []
        var menu: [FinderMenuItem] = []
        var pullScheduled = false

        var allKnown: Set<URL> { known.values.reduce(into: []) { $0.formUnion($1) } }

        mutating func see(_ url: URL) -> Bool {
            guard known[url.deletingLastPathComponent().path, default: []].insert(url).inserted else { return false }
            unbadged.insert(url)
            return true
        }

        mutating func claimPull() -> Bool {
            guard !pullScheduled else { return false }
            pullScheduled = true
            return true
        }

        mutating func takeUnbadged() -> Set<URL> {
            let urls = unbadged
            unbadged = []
            return urls
        }

        mutating func apply(_ badges: FinderBadges, version: Int, watching folders: Set<URL>) -> Bool {
            let foldersChanged = watched != folders
            self.badges = badges
            self.version = version
            watched = folders
            unbadged = []
            return foldersChanged
        }
    }

    private let state = Mutex(State())
    private let queue = DispatchQueue(label: "net.luizkowalski.unlocalfs.finder")
    private let fallback: DispatchSourceTimer
    private var controller: FIFinderSyncController { .default() }

    override init() {
        fallback = DispatchSource.makeTimerSource(queue: queue)
        super.init()
        for badge in FinderBadge.allCases {
            controller.setBadgeImage(badge.image, label: badge.label, forBadgeIdentifier: badge.rawValue)
        }
        var token: Int32 = 0
        notify_register_dispatch(FinderSyncMessage.changedNotification, &token, queue) { [weak self] _ in self?.schedulePull() }
        fallback.schedule(deadline: .now(), repeating: 30)
        fallback.setEventHandler { [weak self] in self?.schedulePull() }
        fallback.resume()
    }

    override func requestBadgeIdentifier(for url: URL) {
        if state.withLock({ $0.see(url) }) {
            schedulePull()
        } else {
            show(state.withLock { $0.badges }, on: [url])
        }
    }

    override func endObservingDirectory(at url: URL) {
        state.withLock { $0.known[url.path] = nil }
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems, let urls = controller.selectedItemURLs(), !urls.isEmpty,
              case let .menu(items) = send(.menu(urls.map { FinderItem(url: $0, isFolder: $0.hasDirectoryPath) })), !items.isEmpty
        else { return nil }
        state.withLock { $0.menu = items }
        let menu = NSMenu(title: "")
        for (index, item) in items.enumerated() {
            let menuItem = NSMenuItem(title: item.title, action: #selector(run(_:)), keyEquivalent: "")
            menuItem.tag = index
            menu.addItem(menuItem)
        }
        return menu
    }

    @objc private func run(_ sender: NSMenuItem) {
        guard let item = state.withLock({ $0.menu.indices.contains(sender.tag) ? $0.menu[sender.tag] : nil }),
              let urls = controller.selectedItemURLs(), !urls.isEmpty else { return }
        _ = send(.run(item.command, files: urls))
    }

    private func schedulePull() {
        guard state.withLock({ $0.claimPull() }) else { return }
        queue.async { [self] in
            state.withLock { $0.pullScheduled = false }
            pull()
        }
    }

    private func pull() {
        switch send(.snapshot(since: state.withLock { $0.version }), timeout: 2) {
        case .unchanged:
            let (badges, urls) = state.withLock { ($0.badges, $0.takeUnbadged()) }
            show(badges, on: urls)
        case let .snapshot(snapshot, version):
            let badges = FinderBadges(snapshot)
            let watched = snapshot.watchedFolders
            let (foldersChanged, urls) = state.withLock { ($0.apply(badges, version: version, watching: watched), $0.allKnown) }
            if foldersChanged { controller.directoryURLs = watched }
            show(badges, on: urls)
        default:
            clear()
        }
    }

    private func clear() {
        let previous = state.withLock { state in
            let previous = state
            state = State()
            return previous
        }
        for url in previous.allKnown {
            controller.setBadgeIdentifier("", for: url)
        }
        if !previous.watched.isEmpty { controller.directoryURLs = [] }
    }

    private func show(_ badges: FinderBadges, on urls: Set<URL>) {
        for url in urls {
            controller.setBadgeIdentifier(badges.badge(for: url)?.rawValue ?? "", for: url)
        }
    }

    private func send(_ request: FinderSyncRequest, timeout: CFTimeInterval = 0.5) -> FinderSyncReply? {
        guard let port = CFMessagePortCreateRemote(nil, FinderSyncMessage.portName as CFString),
              let data = try? FinderSyncMessage.encode(request) else { return nil }
        var reply: Unmanaged<CFData>?
        guard CFMessagePortSendRequest(port, 0, data as CFData, timeout, timeout, CFRunLoopMode.defaultMode.rawValue, &reply) == kCFMessagePortSuccess,
              let reply
        else { return nil }
        return try? FinderSyncMessage.decode(FinderSyncReply.self, from: reply.takeRetainedValue() as Data)
    }
}

private extension FinderBadge {
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

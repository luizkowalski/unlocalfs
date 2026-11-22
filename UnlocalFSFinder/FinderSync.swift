import Cocoa
import FinderSync
import Synchronization
import UnlocalFSDomain

final class FinderSync: FIFinderSync, @unchecked Sendable {
    private struct State {
        var version: Int?
        var badges = FinderBadges(FinderSnapshot(drives: []))
        var watched: Set<URL> = []
        var known: Set<URL> = []
        var menu: [FinderMenuItem] = []
        var pullScheduled = false
    }

    private let state = Mutex(State())
    private let queue = DispatchQueue(label: "net.luizkowalski.unlocalfs.finder")
    private let portName = Bundle.main.object(forInfoDictionaryKey: "FinderPortName") as? String ?? ""
    private let fallback: DispatchSourceTimer

    override init() {
        fallback = DispatchSource.makeTimerSource(queue: queue)
        super.init()
        let controller = FIFinderSyncController.default()
        for badge in FinderBadge.allCases {
            controller.setBadgeImage(badge.image, label: badge.label, forBadgeIdentifier: badge.rawValue)
        }
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in Unmanaged<FinderSync>.fromOpaque(observer!).takeUnretainedValue().schedulePull() },
            FinderSyncMessage.changedNotification as CFString, nil, .deliverImmediately,
        )
        fallback.schedule(deadline: .now(), repeating: 30)
        fallback.setEventHandler { [weak self] in self?.schedulePull() }
        fallback.resume()
    }

    override func requestBadgeIdentifier(for url: URL) {
        let (isNew, badge) = state.withLock { ($0.known.insert(url).inserted, $0.badges.badge(for: url)) }
        if isNew {
            schedulePull()
        } else {
            FIFinderSyncController.default().setBadgeIdentifier(badge?.rawValue ?? "", for: url)
        }
    }

    override func endObservingDirectory(at url: URL) {
        state.withLock { $0.known = $0.known.filter { $0.deletingLastPathComponent().path != url.path } }
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems, let urls = FIFinderSyncController.default().selectedItemURLs(), !urls.isEmpty,
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
              let urls = FIFinderSyncController.default().selectedItemURLs(), !urls.isEmpty else { return }
        _ = send(.run(item.command, files: urls))
    }

    private func schedulePull() {
        guard state.withLock({ state in
            defer { state.pullScheduled = true }
            return !state.pullScheduled
        }) else { return }
        queue.async { [self] in
            state.withLock { $0.pullScheduled = false }
            pull()
        }
    }

    private func pull() {
        switch send(.snapshot(since: state.withLock { $0.version }), timeout: 2) {
        case .unchanged:
            break
        case let .snapshot(snapshot, version):
            let watched = snapshot.watchedFolders
            let changedFolders = state.withLock { state in
                defer { state.watched = watched }
                state.version = version
                state.badges = FinderBadges(snapshot)
                return state.watched != watched
            }
            if changedFolders { FIFinderSyncController.default().directoryURLs = watched }
        default:
            let (known, watching) = state.withLock { state in
                defer { state = State() }
                return (state.known, !state.watched.isEmpty)
            }
            for url in known {
                FIFinderSyncController.default().setBadgeIdentifier("", for: url)
            }
            if watching { FIFinderSyncController.default().directoryURLs = [] }
            return
        }
        let (badges, known) = state.withLock { ($0.badges, $0.known) }
        for url in known {
            FIFinderSyncController.default().setBadgeIdentifier(badges.badge(for: url)?.rawValue ?? "", for: url)
        }
    }

    private func send(_ request: FinderSyncRequest, timeout: CFTimeInterval = 0.5) -> FinderSyncReply? {
        guard let port = CFMessagePortCreateRemote(nil, portName as CFString), let data = try? FinderSyncMessage.encode(request) else { return nil }
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
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: label) ?? NSImage()
        return image.withSymbolConfiguration(NSImage.SymbolConfiguration(paletteColors: [.white, color])) ?? image
    }

    var label: String {
        switch self {
        case .uploaded: String(localized: "Uploaded")
        case .uploading: String(localized: "Uploading")
        case .failed: String(localized: "Upload failed")
        }
    }
}

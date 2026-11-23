import Foundation
import UnlocalFSDomain

extension AppViewModel {
    var finderSnapshot: FinderSnapshot {
        FinderSnapshot(drives: connections.compactMap { connection in
            guard let status = statuses[connection.id], status.isServing else { return nil }
            return FinderSnapshot.Drive(mount: desktop.mountLocation(connection), uploads: status.uploads)
        })
    }

    func finderMenu(for items: [FinderItem]) -> [FinderMenuItem] {
        guard items.allSatisfy({ !$0.isFolder }) else { return [] }
        let owners = items.map { drives.remoteFile($0.url, among: connections)?.connection }
        guard let connection = owners.first ?? nil, owners.allSatisfy({ $0 == connection }) else { return [] }
        var menu: [FinderMenuItem] = []
        if connection.allowsShareLinks {
            menu += ShareLinkExpiry.allCases.map { FinderMenuItem(title: $0.menuTitle, command: .copyShareLink($0)) }
        }
        if connection.allowsServerCopy {
            menu.append(FinderMenuItem(title: String(localized: .duplicateOnServer), command: .duplicateOnServer))
        }
        return menu
    }

    public func reply(to request: FinderSyncRequest) -> FinderSyncReply {
        switch request {
        case let .snapshot(since):
            let snapshot = finderSnapshot
            let version = snapshot.version
            return since == version ? .unchanged(checkedAt: statusCheckedAt) : .snapshot(snapshot, version: version, checkedAt: statusCheckedAt)
        case let .menu(items):
            return .menu(finderMenu(for: items))
        case let .run(command, files):
            Task { await run(command, on: files) }
            return .accepted
        }
    }

    func announceFinderChange() {
        let version = finderSnapshot.version
        guard version != announcedFinderVersion else { return }
        announcedFinderVersion = version
        desktop.announceFinderChange()
    }

    private func run(_ command: FinderCommand, on files: [URL]) async {
        switch command {
        case let .copyShareLink(expiry): await copyShareLinks(for: files, expiry: expiry)
        case .duplicateOnServer: await duplicateOnServer(files)
        }
    }
}

private extension ShareLinkExpiry {
    var menuTitle: String {
        switch self {
        case .hour: String(localized: .copyShareLinkHour)
        case .day: String(localized: .copyShareLinkDay)
        case .week: String(localized: .copyShareLinkWeek)
        }
    }
}

import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    var finderSnapshot: FinderSnapshot {
        FinderSnapshot(drives: connections.compactMap { connection in
            guard let status = statuses[connection.id], status.isServing else { return nil }
            return FinderSnapshot.Drive(mount: desktop.mountLocation(connection), uploads: status.uploads)
        })
    }

    func finderMenu(for items: [FinderItem]) -> [FinderMenuItem] {
        guard !items.isEmpty, items.allSatisfy({ !$0.isFolder }) else { return [] }
        let owners = items.map { drives.remoteFile($0.url, among: connections)?.connection.id }
        guard let id = owners.first ?? nil, owners.allSatisfy({ $0 == id }),
              let connection = connections.first(where: { $0.id == id }) else { return [] }
        var menu: [FinderMenuItem] = []
        if connection.allowsShareLinks {
            menu += ShareLinkExpiry.allCases.map { FinderMenuItem(title: $0.menuTitle, command: .copyShareLink($0)) }
        }
        if connection.allowsServerCopy {
            menu.append(FinderMenuItem(title: String(localized: .duplicateOnServer), command: .duplicateOnServer))
        }
        return menu
    }

    func reply(to request: FinderSyncRequest) -> FinderSyncReply {
        switch request {
        case let .snapshot(since):
            let snapshot = finderSnapshot
            return since == snapshot.version ? .unchanged : .snapshot(snapshot, version: snapshot.version)
        case let .menu(items):
            return .menu(finderMenu(for: items))
        case let .run(command, files):
            Task { await run(command, on: files) }
            return .accepted
        }
    }

    internal func announceFinderChange() {
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

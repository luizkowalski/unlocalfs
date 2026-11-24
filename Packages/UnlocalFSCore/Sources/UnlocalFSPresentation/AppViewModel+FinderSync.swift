import Foundation
import UnlocalFSDomain

extension AppViewModel {
    private var servingDrives: [(connection: Connection, status: MountStatus)] {
        connections.compactMap { connection in servingStatus(connection).map { (connection, $0) } }
    }

    private var finderSnapshot: FinderSnapshot {
        FinderSnapshot(drives: servingDrives.map { FinderSnapshot.Drive(mount: drives.mountLocation($0.connection), uploads: $0.status.uploads) })
    }

    private var finderCheckedAt: [URL: Date] {
        Dictionary(servingDrives.map { (drives.mountLocation($0.connection), statusCheckedAt[$0.connection.id] ?? .distantPast) }, uniquingKeysWith: min)
    }

    private func finderMenu(for files: [URL]) -> [FinderMenuItem] {
        let owners = files.map { try? drives.drive(containing: $0, among: connections).connection }
        guard let connection = owners.first ?? nil, owners.allSatisfy({ $0 == connection }) else { return [] }
        var menu: [FinderMenuItem] = []
        if connection.shareLinkRefusal == nil {
            menu += ShareLinkExpiry.allCases.map { FinderMenuItem(title: $0.menuTitle, command: .copyShareLink($0)) }
        }
        if connection.serverCopyRefusal == nil {
            menu.append(FinderMenuItem(title: String(localized: .duplicateOnServer), command: .duplicateOnServer))
        }
        return menu
    }

    public func reply(to request: FinderSyncRequest) -> FinderSyncReply {
        switch request {
        case let .snapshot(since):
            let snapshot = finderSnapshot
            let version = snapshot.hashValue
            let checkedAt = finderCheckedAt
            return since == version ? .unchanged(checkedAt: checkedAt) : .snapshot(snapshot, version: version, checkedAt: checkedAt)
        case let .menu(files):
            return .menu(finderMenu(for: files))
        case let .run(command, files):
            Task { await perform(command, on: files) }
            return .accepted
        }
    }

    func announceFinderChange() {
        let snapshot = finderSnapshot
        guard snapshot != announcedFinderSnapshot else { return }
        announcedFinderSnapshot = snapshot
        desktop.announceFinderChange()
    }

    private func perform(_ command: FinderCommand, on files: [URL]) async {
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

import Foundation
import UnlocalFSDomain

extension AppViewModel {
    private var servingDrives: [(connection: Connection, status: MountStatus)] {
        connections.compactMap { connection in servingStatus(connection).map { (connection, $0) } }
    }

    private var finderSnapshot: FinderSnapshot {
        FinderSnapshot(drives: servingDrives.map { FinderSnapshot.Drive(mount: desktop.mountLocation($0.connection), uploads: $0.status.uploads) })
    }

    private var finderCheckedAt: [URL: Date] {
        Dictionary(servingDrives.map { (desktop.mountLocation($0.connection), statusCheckedAt[$0.connection.id] ?? .distantPast) }, uniquingKeysWith: min)
    }

    private func finderMenu(for files: [URL]) -> [FinderMenuItem] {
        let owners = files.map { versionsTarget(for: $0)?.connection }
        guard let connection = owners.first ?? nil, owners.allSatisfy({ $0 == connection }) else { return [] }
        let showsVersions = files.count == 1 && connection.versionsRefusal == nil
        if files.contains(where: \.hasDirectoryPath) {
            return showsVersions ? [FinderMenuItem(title: String(localized: .showRecentlyDeleted), command: .showVersions)] : []
        }
        var menu: [FinderMenuItem] = []
        if connection.shareLinkRefusal == nil {
            menu += ShareLinkExpiry.allCases.map { FinderMenuItem(title: $0.menuTitle, command: .copyShareLink($0)) }
        }
        if connection.serverCopyRefusal == nil {
            menu.append(FinderMenuItem(title: String(localized: .duplicateOnServer), command: .duplicateOnServer))
        }
        if showsVersions {
            menu.append(FinderMenuItem(title: String(localized: .showVersions), command: .showVersions))
        }
        return menu
    }

    private func versionsTarget(for file: URL) -> VersionsTarget? {
        if let drive = drives.remoteFile(file, among: connections) {
            return VersionsTarget(connection: drive.connection, path: drive.path, isFolder: file.hasDirectoryPath)
        }
        let driveRoot = connections.first { file.path(inside: desktop.mountLocation($0)) == "" }
        return driveRoot.map { VersionsTarget(connection: $0, path: "", isFolder: true) }
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
            switch command {
            case let .copyShareLink(expiry): Task { await copyShareLinks(for: files, expiry: expiry) }
            case .duplicateOnServer: Task { await duplicateOnServer(files) }
            case .showVersions:
                guard let target = files.first.flatMap(versionsTarget) else { return .failed }
                desktop.showVersions(target)
                return .windowOpened
            }
            return .accepted
        }
    }

    func announceFinderChange() {
        let snapshot = finderSnapshot
        guard snapshot != announcedFinderSnapshot else { return }
        announcedFinderSnapshot = snapshot
        desktop.announceFinderChange()
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

import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func activate(_ connection: Connection) async {
        if canOpen(connection) || !isActive(connection) || needsReconnect(connection) {
            await connect(connection, opensFinder: true)
        }
    }

    func toggle(_ connection: Connection, opensFinder: Bool = false) async {
        if canDisconnect(connection) {
            await disconnect(connection)
        } else {
            await connect(connection, opensFinder: opensFinder)
        }
    }

    private func connect(_ connection: Connection, opensFinder: Bool) async {
        guard !checkingQuit, canToggle(connection) else { return }
        closeSearch()
        busy.insert(connection.id)
        clearProblem(connection)
        defer { busy.remove(connection.id) }
        if let pending = pendingTrust.removeValue(forKey: connection.id) { await drives.cancelServerTrust(pending.challenge) }
        do {
            let outcome = try await connectDrive.execute(connection)
            if opensFinder {
                switch outcome {
                case .connected: openDrive(connection)
                case .ejected: break
                }
            }
        } catch let challenge as ServerTrustChallenge {
            pendingTrust[connection.id] = (challenge, opensFinder)
            errors[connection.id] = challenge.localizedDescription
            selection = .drive(connection.id)
        } catch {
            if error is GoogleSignInRequired { signInRequired.insert(connection.id) }
            errors[connection.id] = error.localizedDescription
        }
        await update(drives.status(connection), for: connection)
    }

    func disconnect(_ connection: Connection) async {
        guard !checkingQuit, canDisconnect(connection) else { return }
        busy.insert(connection.id)
        clearProblem(connection)
        if disconnectFailure?.id == connection.id { disconnectFailure = nil }
        waitingToDisconnect.remove(connection.id)
        defer { busy.remove(connection.id) }
        do {
            try await drives.unmount(connection)
        } catch is UploadsPendingError {
            uploadsBlockingDisconnect = connection
            waitingToDisconnect.insert(connection.id)
            selection = .drive(connection.id)
        } catch is DriveEjectError {
            disconnectFailure = connection
        } catch {
            errors[connection.id] = error.localizedDescription
        }
        await update(drives.status(connection), for: connection)
    }

    func serverTrust(for connection: Connection) -> ServerTrustChallenge? {
        pendingTrust[connection.id]?.challenge
    }

    func trustServer(_ connection: Connection) async {
        guard let pending = pendingTrust.removeValue(forKey: connection.id) else { return }
        busy.insert(connection.id)
        do {
            try await drives.trustServer(pending.challenge)
            busy.remove(connection.id)
            await connect(connection, opensFinder: pending.opensFinder)
        } catch {
            busy.remove(connection.id)
            errors[connection.id] = error.localizedDescription
        }
    }

    func cancelServerTrust(_ connection: Connection) async {
        guard let pending = pendingTrust.removeValue(forKey: connection.id) else { return }
        await drives.cancelServerTrust(pending.challenge)
    }

    func disconnectAll() async {
        for connection in connections where canDisconnect(connection) {
            await disconnect(connection)
            if isActive(connection) {
                selection = .drive(connection.id)
                return
            }
        }
    }

    internal func connectAutomatically() async {
        await withTaskGroup(of: Void.self) { group in
            for connection in connections {
                if let status = statuses[connection.id], connection.shouldConnectAutomatically(status: status) {
                    group.addTask { await self.connect(connection, opensFinder: false) }
                }
            }
        }
    }

    internal func clearProblem(_ connection: Connection) {
        errors[connection.id] = nil
        signInRequired.remove(connection.id)
    }
}

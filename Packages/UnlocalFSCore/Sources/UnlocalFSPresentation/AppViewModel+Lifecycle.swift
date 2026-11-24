import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func activate(_ connection: Connection) async {
        if canOpen(connection) || !isActive(connection) || needsReconnect(connection) {
            await connect(connection, opensFinder: true)
        }
    }

    func toggle(_ connection: Connection) async {
        switch driveToggle(connection) {
        case .connect: await connect(connection, opensFinder: true)
        case .disconnect: await disconnect(connection)
        case .reconnect: await reconnect(connection)
        }
    }

    private func connect(_ connection: Connection, opensFinder: Bool) async {
        await operate(on: connection, when: canToggle(connection)) {
            closeSearch()
            clearProblem(connection)
            if let pending = pendingTrust.removeValue(forKey: connection.id) { await drives.cancelServerTrust(pending.challenge) }
            do {
                let outcome = try await connectDrive.execute(connection)
                if opensFinder, outcome == .connected { openDrive(connection) }
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
    }

    func disconnect(_ connection: Connection) async {
        await operate(on: connection, when: canDisconnect(connection)) {
            clearProblem(connection)
            if disconnectFailure?.id == connection.id { disconnectFailure = nil }
            waitingToDisconnect.remove(connection.id)
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
    }

    func serverTrust(for connection: Connection) -> ServerTrustChallenge? {
        pendingTrust[connection.id]?.challenge
    }

    func trustServer(_ connection: Connection) async {
        guard let pending = pendingTrust[connection.id] else { return }
        let trusted = await operate(on: connection, when: canToggle(connection)) {
            pendingTrust[connection.id] = nil
            do {
                try await drives.trustServer(pending.challenge)
                return true
            } catch {
                errors[connection.id] = error.localizedDescription
                return false
            }
        }
        if trusted == true { await connect(connection, opensFinder: pending.opensFinder) }
    }

    func cancelServerTrust(_ connection: Connection) async {
        guard let pending = pendingTrust.removeValue(forKey: connection.id) else { return }
        await drives.cancelServerTrust(pending.challenge)
    }

    func reconnect(_ connection: Connection) async {
        guard canReconnect(connection) else { return }
        await connect(connection, opensFinder: false)
    }

    func disconnectAll() async {
        guard !disconnectingAll else { return }
        disconnectingAll = true
        defer { disconnectingAll = false }
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

    @discardableResult
    internal func operate<Result>(on connection: Connection, when allowed: Bool, _ body: () async -> Result) async -> Result? {
        guard allowed else { return nil }
        busy.insert(connection.id)
        defer { busy.remove(connection.id) }
        return await body()
    }

    internal func clearProblem(_ connection: Connection) {
        errors[connection.id] = nil
        signInRequired.remove(connection.id)
    }
}

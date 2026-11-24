import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func beginQuit() -> Bool {
        guard !checkingQuit else { return false }
        checkingQuit = true
        return true
    }

    func quitDecision() async -> QuitUseCase.Decision {
        await quit.execute(connections: connections, operationInProgress: !busy.isEmpty)
    }

    func cancelQuit() { checkingQuit = false }

    func stopSignInsForQuit() async { await drives.stopSignIns() }

    func disconnectForQuit() async -> (connection: Connection, error: any Error)? {
        let active = Set(connections.filter(isActive).map(\.id))
        busy.formUnion(active)
        let failure = await quit.disconnectAll(connections: connections)
        busy.subtract(active)
        await refresh()
        return failure
    }
}

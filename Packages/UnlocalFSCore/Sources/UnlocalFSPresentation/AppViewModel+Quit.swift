import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func quitDecision() async -> QuitUseCase.Decision {
        checkingQuit = true
        return await quit.execute(connections: connections, operationInProgress: !busy.isEmpty)
    }

    func cancelQuit() { checkingQuit = false }

    func stopSignInsForQuit() async { await drives.stopSignIns() }

    func disconnectForQuit() async -> (connection: Connection, error: any Error)? {
        checkingQuit = true
        let active = Set(connections.filter(isActive).map(\.id))
        busy.formUnion(active)
        let failure = await quit.disconnectAll(connections: connections)
        busy.subtract(active)
        await refresh()
        return failure
    }
}

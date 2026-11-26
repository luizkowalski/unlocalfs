import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func quitDecision() async -> QuitUseCase.Decision {
        checkingQuit = true
        return await quit.execute(connections: connections, operationInProgress: !busy.isEmpty)
    }

    func cancelQuit() { checkingQuit = false }

    func stopSignInsForQuit() async { await drives.stopSignIns() }

    func disconnectForQuit(_ active: [Connection]) async -> (connection: Connection, error: any Error)? {
        await unmountAll(active)
    }
}

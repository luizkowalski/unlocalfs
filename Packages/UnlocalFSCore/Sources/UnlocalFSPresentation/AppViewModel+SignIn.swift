import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func signInAgain(_ connection: Connection) async {
        guard !checkingQuit, canToggle(connection) else { return }
        busy.insert(connection.id)
        let previousError = errors.removeValue(forKey: connection.id)
        defer { busy.remove(connection.id) }
        let run = GoogleSignInRun(drives: drives)
        signIns[connection.id] = run
        let token = await run.token()
        signIns[connection.id] = nil
        guard let token else {
            errors[connection.id] = previousError
            return
        }
        do {
            try await googleSignIn.execute(connection, token: token.get())
            signInRequired.remove(connection.id)
        } catch {
            errors[connection.id] = error.localizedDescription
        }
        await update(drives.status(connection), for: connection)
    }

    func cancelSignIn(_ connection: Connection) {
        signIns.removeValue(forKey: connection.id)?.cancel()
    }

    func isSigningIn(_ connection: Connection) -> Bool { signIns[connection.id] != nil }

    func needsSignIn(_ connection: Connection) -> Bool {
        signInRequired.contains(connection.id) || statuses[connection.id]?.needsSignIn == true
    }
}

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
        let result = await run.signIn(for: connection.backend)
        signIns[connection.id] = nil
        guard let result else {
            errors[connection.id] = previousError
            return
        }
        do {
            try await signInAgain.execute(connection, signIn: result.get())
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

import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func signInAgain(_ connection: Connection) async {
        guard !checkingQuit, canToggle(connection) else { return }
        busy.insert(connection.id)
        errors[connection.id] = nil
        defer { busy.remove(connection.id) }
        let signIn = Task { [drives] in try await drives.signInWithGoogle() }
        signIns[connection.id] = signIn
        let token = await signIn.result
        guard signIns.removeValue(forKey: connection.id) == signIn else { return }
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

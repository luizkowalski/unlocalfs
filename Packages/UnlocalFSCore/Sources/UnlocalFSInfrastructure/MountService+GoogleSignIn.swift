import Foundation
import UnlocalFSDomain

public struct GoogleClient: Sendable {
    public let id: String
    public let secret: String

    public init(id: String, secret: String) {
        self.id = id
        self.secret = secret
    }

    func requireConfigured() throws {
        guard !id.isEmpty, !secret.isEmpty else { throw AppError(String(localized: .googleSignInUnavailable)) }
    }
}

extension MountService {
    private static let signInTimeout = Duration.seconds(300)
    private static let tokenStart = "Paste the following into your remote machine --->\n"
    private static let tokenEnd = "\n<---End paste"
    private static let driveAbout = URL(string: "https://www.googleapis.com/drive/v3/about?fields=user(permissionId)")!

    public func signInWithGoogle(for backend: Backend) async throws -> GoogleSignIn {
        try googleClient.requireConfigured()
        guard signIns.isEmpty else { throw AppError(String(localized: .googleSignInInProgress)) }
        let page = Bundle.module.url(forResource: "GoogleSignIn", withExtension: "html")!.path
        let prefix = "RCLONE_\(backend.rcloneType.uppercased())_"
        var variables = [prefix + "CLIENT_ID": googleClient.id, prefix + "CLIENT_SECRET": googleClient.secret]
        if backend == .googleDrive { variables[prefix + "SCOPE"] = RcloneRemote.driveScope }
        let run = Task { [executable, environment = environment(variables)] in
            try await Command.run(
                executable, ["authorize", backend.rcloneType, "--template", page, "--config", "/dev/null"],
                environment: environment, timeout: Self.signInTimeout,
            )
        }
        signIns.insert(run)
        defer { signIns.remove(run) }
        let output: Data
        do {
            output = try await withTaskCancellationHandler { try await run.value } onCancel: { run.cancel() }
        } catch let error as AppError {
            let reason = error.localizedDescription.components(separatedBy: "Fatal error: ").last!
            throw AppError(reason.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let text = String(decoding: output, as: UTF8.self)
        guard let start = text.range(of: Self.tokenStart), let end = text.range(of: Self.tokenEnd, range: start.upperBound ..< text.endIndex),
              let token = GoogleToken(json: String(text[start.upperBound ..< end.lowerBound]))
        else { throw AppError(String(localized: .googleSignInFailed)) }
        guard backend == .googleDrive else { return GoogleSignIn(token: token.json) }
        return try await GoogleSignIn(token: token.json, accountID: driveAccountID(accessToken: token.accessToken))
    }

    private func driveAccountID(accessToken: String) async throws -> String {
        var request = URLRequest(url: Self.driveAbout)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200, let about = try? JSONDecoder().decode(DriveAbout.self, from: data),
              !about.user.permissionId.isEmpty
        else { throw AppError(String(localized: .googleSignInFailed)) }
        return about.user.permissionId
    }

    public func applyGoogleSignIn(_ connection: Connection, credentials: Credentials) async throws {
        let storage = try await remote(for: connection, credentials: credentials).storageRemote
        do {
            _ = try await control(connection, "config/update", body: JSONEncoder().encode(storage))
            for upload in try await control(UploadQueue.self, connection, "vfs/queue").queue where upload.hasFailedAttempt {
                _ = try? await control(connection, "vfs/queue-set-expiry", ["id": "\(upload.id)", "expiry": "0"])
            }
        } catch {
            throw redacted(error, credentials: credentials)
        }
    }

    public func stopSignIns() async {
        for run in signIns {
            run.cancel()
            _ = await run.result
        }
    }

    func isRevokedGrant(_ connection: Connection, error message: String?) -> Bool {
        connection.usesGoogleSignIn && message?.contains("invalid_grant") == true
    }
}

private struct DriveAbout: Decodable {
    struct User: Decodable { let permissionId: String }
    let user: User
}

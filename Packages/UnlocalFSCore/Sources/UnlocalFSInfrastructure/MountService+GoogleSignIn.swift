import Foundation
import UnlocalFSDomain

public struct GoogleClient: Sendable {
    public let id: String
    public let secret: String

    public init(id: String, secret: String) {
        self.id = id
        self.secret = secret
    }
}

extension MountService {
    private static let signInTimeout = Duration.seconds(300)
    private static let tokenStart = "Paste the following into your remote machine --->\n"
    private static let tokenEnd = "\n<---End paste"

    public func signInWithGoogle() async throws -> String {
        try requireGoogleClient()
        let page = Bundle.module.url(forResource: "GoogleSignIn", withExtension: "html")!.path
        let output: Data
        do {
            output = try await Command.run(
                executable, ["authorize", "gcs", "--template", page, "--config", "/dev/null"],
                environment: environment(["RCLONE_GCS_CLIENT_ID": googleClient.id, "RCLONE_GCS_CLIENT_SECRET": googleClient.secret]),
                timeout: Self.signInTimeout,
            )
        } catch let error as AppError {
            let reason = error.localizedDescription.components(separatedBy: "Fatal error: ").last!
            throw AppError(reason.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let text = String(decoding: output, as: UTF8.self)
        guard let start = text.range(of: Self.tokenStart), let end = text.range(of: Self.tokenEnd, range: start.upperBound ..< text.endIndex),
              let token = GoogleToken(json: String(text[start.upperBound ..< end.lowerBound]))
        else { throw AppError(String(localized: .googleSignInFailed)) }
        return token.json
    }

    public func applyGoogleSignIn(_ connection: Connection, credentials: Credentials) async throws {
        try requireGoogleSignIn(connection, credentials: credentials)
        let storage = try await remote(for: connection, credentials: credentials).storageRemote
        do {
            _ = try await control(connection, "config/update", body: JSONEncoder().encode(CreateRemote(storage)))
            for upload in try await control(UploadQueue.self, connection, "vfs/queue").queue where upload.hasFailedAttempt {
                _ = try? await control(connection, "vfs/queue-set-expiry", ["id": "\(upload.id)", "expiry": "0"])
            }
        } catch {
            throw redacted(error, credentials: credentials)
        }
    }

    func requireGoogleSignIn(_ connection: Connection, credentials: Credentials) throws {
        guard connection.usesGoogleSignIn else { return }
        try requireGoogleClient()
        guard credentials.isSignedInToGoogle else { throw GoogleSignInRequired() }
    }

    func isRevokedGrant(_ connection: Connection, _ message: String?) -> Bool {
        connection.usesGoogleSignIn && message?.contains("invalid_grant") == true
    }

    private func requireGoogleClient() throws {
        guard !googleClient.id.isEmpty else { throw AppError(String(localized: .googleSignInUnavailable)) }
    }
}

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
        let page = Bundle.module.url(forResource: "GoogleSignIn", withExtension: "html")?.path ?? ""
        let output: Data
        do {
            output = try await Command.run(
                executable, ["authorize", "gcs", "--template", page, "--config", "/dev/null"],
                environment: environment(["RCLONE_GCS_CLIENT_ID": googleClient.id, "RCLONE_GCS_CLIENT_SECRET": googleClient.secret]),
                timeout: Self.signInTimeout,
            )
        } catch let error as AppError {
            let reason = error.localizedDescription.components(separatedBy: "Fatal error: ").last ?? ""
            throw AppError(reason.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let text = String(decoding: output, as: UTF8.self)
        guard let start = text.range(of: Self.tokenStart), let end = text.range(of: Self.tokenEnd, range: start.upperBound ..< text.endIndex),
              let token = GoogleToken(json: String(text[start.upperBound ..< end.lowerBound]))
        else { throw AppError(String(localized: .googleSignInFailed)) }
        return token.json
    }

    func requireGoogleSignIn(_ connection: Connection, credentials: Credentials) throws {
        guard connection.backend == .gcs, connection.gcs.authentication == .googleAccount else { return }
        try requireGoogleClient()
        guard credentials.isSignedInToGoogle else { throw GoogleSignInRequired() }
    }

    private func requireGoogleClient() throws {
        guard !googleClient.id.isEmpty else { throw AppError(String(localized: .googleSignInUnavailable)) }
    }
}

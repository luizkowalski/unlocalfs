import Foundation
import UnlocalFSDomain

extension MountService {
    public func exportRcloneConfig(_ connection: Connection, credentials: Credentials?, to destination: URL) async throws {
        guard connection.rclonePath.last?.isWhitespace != true else {
            throw AppError(String(localized: .folderEndsWithSpace))
        }
        if let credentials { try requireGoogleSignIn(connection, credentials: credentials) }
        var prepared: Credentials?
        if let credentials { prepared = try await prepareCredentials(credentials) }
        let scratch = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: destination, create: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        let config = scratch.appending(path: "rclone.conf")
        let remote = try await RcloneRemote(connection: connection, credentials: prepared, knownHosts: serverTrust.file(), googleClient: googleClient)
        do {
            for named in remote.namedRemotes {
                try await create(named, config: config)
            }
        } catch {
            throw redacted(error, credentials: prepared ?? Credentials())
        }
        _ = try FileManager.default.replaceItemAt(destination, withItemAt: config, options: .usingNewMetadataOnly)
    }

    private func create(_ remote: NamedRemote, config: URL) async throws {
        let parameters = remote.parameters.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
        _ = try await Command.run(executable, [
            "config", "create", remote.name, remote.type,
        ] + parameters + [
            "--no-obscure", "--non-interactive", "--no-output", "--config", config.path,
        ], environment: baseEnvironment)
    }
}

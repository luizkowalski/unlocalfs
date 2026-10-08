import Foundation
import UnlocalFSDomain

extension MountService {
    public func exportRcloneConfig(_ connection: Connection, credentials: Credentials?, to destination: URL) async throws {
        guard RcloneRemote(connection: connection, credentials: nil, knownHosts: paths.knownHosts).path.last?.isWhitespace != true else {
            throw AppError(String(localized: .folderEndsWithSpace))
        }
        var prepared: Credentials?
        if let credentials { prepared = try await prepareCredentials(credentials) }
        let scratch = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: destination, create: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        let config = scratch.appending(path: "rclone.conf")
        let remote = RcloneRemote(connection: connection, credentials: prepared, knownHosts: paths.knownHosts)
        var crypt = [
            "remote": "\(remote.exportName):\(remote.path)", "filename_encryption": "standard",
            "directory_name_encryption": "true", "filename_encoding": "base32"
        ]
        crypt["password"] = prepared?.obscuredEncryptionPassword
        do {
            try await createRemote(remote.exportName, type: remote.type, options: remote.options, config: config)
            try await createRemote("unlocalfs", type: "crypt", options: crypt, config: config)
        } catch {
            throw redacted(error, credentials: prepared ?? Credentials())
        }
        _ = try FileManager.default.replaceItemAt(destination, withItemAt: config, options: .usingNewMetadataOnly)
    }

    private func createRemote(_ name: String, type: String, options: [String: String], config: URL) async throws {
        let parameters = options.filter { !$0.value.isEmpty }.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
        _ = try await Command.run(executable, [
            "config", "create", name, type] + parameters + [
            "--no-obscure", "--non-interactive", "--no-output", "--config", config.path
        ], environment: baseEnvironment)
    }
}

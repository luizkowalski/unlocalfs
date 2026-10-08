import Foundation
import UnlocalFSDomain

actor SFTPTrustStore {
    private struct Pending {
        let server: String
        let keys: String
        let previous: Data
    }

    private let paths: AppPaths
    private var pending: [UUID: Pending] = [:]

    init(paths: AppPaths) { self.paths = paths }

    func file() throws -> URL {
        try paths.prepare()
        let file = paths.knownHosts
        if !FileManager.default.fileExists(atPath: file.path) {
            try Data().write(to: file, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        }
        return file
    }

    func challenge(_ sftp: SFTPSettings, keyChanged: Bool) async throws -> ServerTrustChallenge {
        let previous = try Data(contentsOf: file())
        let output = try await Command.run(URL(filePath: "/usr/bin/ssh-keyscan"), [
            "-T", "5", "-p", "\(sftp.port)", "-t", "ed25519,ecdsa,rsa", "--", sftp.host
        ], timeout: .seconds(20))
        let keys = String(decoding: output, as: UTF8.self).split(separator: "\n").filter {
            !$0.hasPrefix("#") && $0.split(separator: " ").count == 3
        }.joined(separator: "\n") + "\n"
        let scratch = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: scratch) }
        let scanned = scratch.appending(path: "keys")
        try keys.write(to: scanned, atomically: true, encoding: .utf8)
        let fingerprints = try await Command.run(URL(filePath: "/usr/bin/ssh-keygen"), ["-lf", scanned.path, "-E", "sha256"])
        let challenge = ServerTrustChallenge(
            id: UUID(), host: sftp.host, port: sftp.port,
            fingerprints: String(decoding: fingerprints, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines), keyChanged: keyChanged
        )
        let server = sftp.port == 22 ? sftp.host : "[\(sftp.host)]:\(sftp.port)"
        pending[challenge.id] = Pending(server: server, keys: keys, previous: previous)
        return challenge
    }

    func accept(_ challenge: ServerTrustChallenge) async throws {
        guard let request = pending.removeValue(forKey: challenge.id) else { throw AppError(String(localized: .serverTrustExpired)) }
        let file = try file()
        let scratch = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: scratch) }
        let replacement = scratch.appending(path: "known_hosts")
        try request.previous.write(to: replacement)
        _ = try await Command.run(URL(filePath: "/usr/bin/ssh-keygen"), ["-R", request.server, "-f", replacement.path])
        var keys = try String(contentsOf: replacement, encoding: .utf8)
        if !keys.isEmpty && !keys.hasSuffix("\n") { keys += "\n" }
        keys += request.keys
        guard try Data(contentsOf: file) == request.previous else { throw AppError(String(localized: .serverTrustExpired)) }
        try Data(keys.utf8).write(to: file, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    }

    func cancel(_ challenge: ServerTrustChallenge) { pending[challenge.id] = nil }

    private func scratchDirectory() throws -> URL {
        try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: paths.support, create: true)
    }
}

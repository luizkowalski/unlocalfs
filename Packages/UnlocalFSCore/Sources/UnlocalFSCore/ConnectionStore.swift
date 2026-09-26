import Foundation

public struct ConnectionStore: Sendable {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func all() throws -> [Connection] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let config = try JSONDecoder().decode(Config.self, from: Data(contentsOf: url))
        return config.connections.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func save(_ connection: Connection) throws {
        try connection.validate()
        let others = try all().filter { $0.id != connection.id }
        guard !others.contains(where: { $0.name.caseInsensitiveCompare(connection.name) == .orderedSame }) else {
            throw AppError("A drive with that name already exists.")
        }
        try write(others + [connection])
    }

    public func delete(_ id: UUID) throws {
        try write(all().filter { $0.id != id })
    }

    private func write(_ connections: [Connection]) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(Config(connections: connections)).write(to: url, options: .atomic)
    }
}

private struct Config: Codable {
    var connections: [Connection]
}

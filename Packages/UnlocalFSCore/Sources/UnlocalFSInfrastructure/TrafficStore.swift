import Foundation
import GRDB
import UnlocalFSDomain

public final class TrafficStore: TrafficRepository {
    private let database: Result<DatabaseQueue, any Error>

    public init(url: URL) {
        database = Result {
            let database = try DatabaseQueue(path: url.path)
            try Self.migrator.migrate(database)
            return database
        }
    }

    public func traffic(in days: ClosedRange<TrafficDay>) throws -> [DriveTraffic] {
        try database.get().read { sqlite in
            try Row.fetchAll(sqlite, sql: """
                SELECT unlocal.id, unlocal.name, unlocal.provider, SUM(traffic.upload) AS upload, SUM(traffic.download) AS download
                FROM traffic JOIN unlocal ON unlocal.id = traffic.unlocal_id
                WHERE traffic.day BETWEEN ? AND ?
                GROUP BY unlocal.id
                """, arguments: [days.lowerBound.rawValue, days.upperBound.rawValue]
            ).map { row in
                DriveTraffic(
                    id: row["id"], name: row["name"], provider: Provider(rawValue: row["provider"]) ?? .other,
                    traffic: Traffic(upload: row["upload"], download: row["download"])
                )
            }
        }
    }

    public func dailyTraffic(in days: ClosedRange<TrafficDay>) throws -> [TrafficDay: Traffic] {
        try database.get().read { sqlite in
            let rows = try Row.fetchAll(sqlite, sql: """
                SELECT day, SUM(upload) AS upload, SUM(download) AS download FROM traffic
                WHERE day BETWEEN ? AND ?
                GROUP BY day
                """, arguments: [days.lowerBound.rawValue, days.upperBound.rawValue]
            )
            return Dictionary(uniqueKeysWithValues: rows.map { (TrafficDay(rawValue: $0["day"]), Traffic(upload: $0["upload"], download: $0["download"])) })
        }
    }

    func checkpoint(for id: UUID) throws -> TrafficCheckpoint? {
        try database.get().read { sqlite in
            guard let row = try Row.fetchOne(sqlite, sql: "SELECT * FROM unlocal WHERE id = ?", arguments: [id]) else { return nil }
            return TrafficCheckpoint(
                process: RcloneProcess(pid: row["pid"], startedAt: Date(timeIntervalSinceReferenceDate: row["process_started_at"])),
                network: row["network"], savedAt: Date(timeIntervalSinceReferenceDate: row["saved_at"])
            )
        }
    }

    func save(_ save: TrafficSave, for connection: Connection) throws {
        let checkpoint = save.checkpoint
        try database.get().write { sqlite in
            try sqlite.execute(sql: """
                INSERT INTO unlocal (id, name, provider, pid, process_started_at, network, saved_at) VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (id) DO UPDATE SET
                    name = excluded.name, provider = excluded.provider, pid = excluded.pid, process_started_at = excluded.process_started_at,
                    network = excluded.network, saved_at = excluded.saved_at
                """, arguments: [
                    connection.id, connection.name, connection.provider.rawValue, checkpoint.process.pid,
                    checkpoint.process.startedAt.timeIntervalSinceReferenceDate, checkpoint.network, checkpoint.savedAt.timeIntervalSinceReferenceDate,
                ]
            )
            try sqlite.execute(sql: """
                INSERT INTO traffic (unlocal_id, day, upload, download) VALUES (?, ?, ?, ?)
                ON CONFLICT (unlocal_id, day) DO UPDATE SET upload = upload + excluded.upload, download = download + excluded.download
                """, arguments: [connection.id, save.day.rawValue, save.traffic.upload, save.traffic.download]
            )
        }
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { sqlite in
            try sqlite.execute(sql: """
                CREATE TABLE unlocal (
                    id BLOB PRIMARY KEY NOT NULL,
                    name TEXT NOT NULL,
                    provider TEXT NOT NULL,
                    pid INTEGER NOT NULL,
                    process_started_at DOUBLE NOT NULL,
                    network INTEGER NOT NULL,
                    saved_at DOUBLE NOT NULL
                );
                CREATE TABLE traffic (
                    unlocal_id BLOB NOT NULL REFERENCES unlocal (id),
                    day TEXT NOT NULL,
                    upload INTEGER NOT NULL,
                    download INTEGER NOT NULL,
                    PRIMARY KEY (unlocal_id, day)
                );
                """)
        }
        return migrator
    }
}

import Darwin
import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

let helpers = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .appendingPathComponent("../../../../libexec").standardized

let rcloneExecutable = Task {
    let script = helpers.deletingLastPathComponent().appending(path: "scripts/fetch-rclone.sh")
    let output = try await Command.run(script, [])
    return URL(fileURLWithPath: String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
}

struct Drive: Sendable {
    let executable: URL
    let paths: AppPaths
    let service: MountService
    let traffic: TrafficStore
    let connection: Connection

    var mounted: URL { paths.mount(connection) }
    var knownHosts: URL { paths.support.appending(path: "known_hosts") }

    func control(_ method: String, _ parameters: String...) async throws -> [String: Any] {
        let data = try await Command.run(
            executable, ["rc", "--unix-socket", paths.socket(connection).path, method] + parameters + ["--config", "/dev/null"]
        )
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func waitForUploads() async throws {
        try await waitUntil(timeout: .seconds(20)) {
            let queue = try? await control("vfs/queue")["queue"] as? [[String: Any]]
            for item in (queue ?? []).compactMap({ $0["id"] as? Int }) {
                _ = try? await control("vfs/queue-set-expiry", "id=\(item)", "expiry=-60", "relative=true")
            }
            return await service.status(connection).pendingUploads == 0
        }
    }

    func activity(of path: String, where matches: (FileActivity) -> Bool) async throws -> FileActivity {
        var found: FileActivity?
        try await waitUntil(timeout: .seconds(10)) {
            found = try await service.activity(connection).first { $0.path == path && matches($0) }
            return found != nil
        }
        return try #require(found)
    }

    func disconnect() async throws {
        let savedPID = try? String(contentsOf: paths.pidFile(connection), encoding: .utf8)
        let pid = savedPID.flatMap { pid_t($0) }
        if await service.status(connection).isActive {
            try? await waitForUploads()
            try? await service.unmount(connection)
        }
        if await service.status(connection).isMounted {
            _ = try? await Command.run(URL(filePath: "/sbin/umount"), ["-f", mounted.path], timeout: .seconds(10))
        }
        if let pid, kill(pid, 0) == 0 {
            kill(pid, SIGKILL)
            try await waitUntil(timeout: .seconds(5)) { kill(pid, 0) != 0 && errno == ESRCH }
        }
        try await waitUntil(timeout: .seconds(5)) {
            let status = await service.status(connection)
            return !status.isMounted && !status.isRunning
        }
    }
}

func makeDrive(executable: URL, resources: FixtureResources, connection: Connection) async throws -> Drive {
    let root = resources.root
    let paths = AppPaths(
        config: root.appending(path: "config.json"), support: root.appending(path: "app"),
        mounts: root.appending(path: "drives"), logs: root.appending(path: "logs")
    )
    try paths.prepare()
    let traffic = TrafficStore(url: paths.traffic)
    let drive = Drive(
        executable: executable, paths: paths,
        service: MountService(executable: executable, helperDirectory: helpers, paths: paths, traffic: traffic), traffic: traffic, connection: connection
    )
    await resources.track(drive)
    return drive
}

func verifyRoundTrip(_ drive: Drive, storage: URL, credentials: Credentials) async throws {
    try Data("from the server".utf8).write(to: storage.appending(path: "remote.txt"))
    try await drive.service.mount(drive.connection, credentials: credentials)
    #expect(try String(contentsOf: drive.mounted.appending(path: "remote.txt"), encoding: .utf8) == "from the server")
    let downloaded = try await drive.activity(of: "remote.txt") { if case .downloaded = $0.state { true } else { false } }
    #expect(downloaded.size == 15 && downloaded.bytesTransferred == 15)

    try Data("from Finder".utf8).write(to: drive.mounted.appending(path: "local.txt"))
    let queued = try await drive.activity(of: "local.txt") { $0.state == .queued }
    #expect(queued.size == 11)
    await #expect(throws: UploadsPendingError.self) { try await drive.service.unmount(drive.connection) }
    try await drive.waitForUploads()
    #expect(try String(contentsOf: storage.appending(path: "local.txt"), encoding: .utf8) == "from Finder")
    _ = try await drive.activity(of: "local.txt") { if case .uploaded = $0.state { true } else { false } }

    try FileManager.default.removeItem(at: drive.mounted.appending(path: "remote.txt"))
    #expect(!FileManager.default.fileExists(atPath: storage.appending(path: "remote.txt").path))

    let beforeRename = await drive.service.status(drive.connection).unsavedTraffic
    try FileManager.default.moveItem(at: drive.mounted.appending(path: "local.txt"), to: drive.mounted.appending(path: "renamed.txt"))
    try await waitUntil(timeout: .seconds(10)) { FileManager.default.fileExists(atPath: storage.appending(path: "renamed.txt").path) }
    #expect(await drive.service.status(drive.connection).unsavedTraffic == beforeRename)

    try await drive.service.unmount(drive.connection)
    #expect(await !drive.service.status(drive.connection).isActive)
    let today = TrafficDay(.now, calendar: .current)
    let recorded = try #require(try drive.traffic.traffic(from: today, through: today).first { $0.id == drive.connection.id })
    #expect(recorded.traffic.upload >= 11 && recorded.traffic.download >= 15)
}

func rclone(_ drive: Drive, _ config: URL, _ arguments: String...) async throws -> String {
    let output = try await Command.run(
        drive.executable, arguments + ["--config", config.path], environment: ["HOME": URL.homeDirectory.path, "PATH": "/usr/bin:/bin"]
    )
    return String(decoding: output, as: UTF8.self)
}

func dump(_ drive: Drive, _ config: URL) async throws -> [String: [String: String]] {
    try await JSONDecoder().decode([String: [String: String]].self, from: Data(rclone(drive, config, "config", "dump").utf8))
}

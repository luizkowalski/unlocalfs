import Darwin
import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

actor FixtureResources {
    let root: URL
    private var processes: [Process] = []
    private var logs: [FileHandle] = []
    private var drive: Drive?

    init() throws {
        root = URL(filePath: "/tmp/uf-\(UUID().uuidString.prefix(8))")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func start(_ executable: URL, arguments: [String], log name: String) throws -> Process {
        let url = root.appending(path: name)
        if !FileManager.default.fileExists(atPath: url.path) { FileManager.default.createFile(atPath: url.path, contents: nil) }
        let log = try FileHandle(forWritingTo: url)
        try log.seekToEnd()
        logs.append(log)
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = ["PATH": "/usr/bin:/bin", "HOME": URL.homeDirectory.path, "LANG": "en_US.UTF-8"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = log
        process.standardError = log
        try process.run()
        processes.append(process)
        return process
    }

    func track(_ drive: Drive) { self.drive = drive }

    func stop(_ process: Process) async throws {
        guard process.isRunning else { return }
        process.terminate()
        do {
            try await waitUntil(timeout: .seconds(2)) { !process.isRunning }
        } catch {
            kill(process.processIdentifier, SIGKILL)
            try await waitUntil(timeout: .seconds(2)) { !process.isRunning }
        }
    }

    func cleanup() async throws {
        var failures: [String] = []
        if let drive {
            do { try await drive.disconnect() } catch { failures.append("Drive cleanup: \(error)") }
        }
        for process in processes.reversed() {
            do { try await stop(process) } catch { failures.append("Process \(process.processIdentifier) cleanup: \(error)") }
        }
        for log in logs {
            do { try log.close() } catch { failures.append("Log cleanup: \(error)") }
        }
        if !failures.isEmpty { throw AppError(failures.joined(separator: "\n")) }
    }
}

func withFixture(_ body: (FixtureResources) async throws -> Void) async throws {
    let resources = try FixtureResources()
    do {
        try await body(resources)
    } catch {
        do { try await Task.detached { try await resources.cleanup() }.value } catch { Issue.record(error) }
        throw error
    }
    try await Task.detached { try await resources.cleanup() }.value
    try FileManager.default.removeItem(at: resources.root)
}

func requireReady(_ process: Process, log: URL, _ probe: () async throws -> Void) async throws {
    var lastFailure: (any Error)?
    do {
        try await waitUntil {
            guard process.isRunning else { throw AppError("Fixture process exited with status \(process.terminationStatus)") }
            do {
                try await probe()
                return true
            } catch let error as CancellationError {
                throw error
            } catch {
                lastFailure = error
                return false
            }
        }
    } catch let error as CancellationError {
        throw error
    } catch {
        let output = (try? String(contentsOf: log, encoding: .utf8)) ?? ""
        throw AppError("Fixture readiness failed: \(error)\nLast probe: \(String(describing: lastFailure))\n\(output)")
    }
}

func makeDrive(executable: URL, bucket: URL, resources: FixtureResources, connection: Connection) async -> Drive {
    let root = resources.root
    let paths = AppPaths(
        config: root.appending(path: "config.json"), support: root.appending(path: "app"),
        mounts: root.appending(path: "drives"), logs: root.appending(path: "logs")
    )
    let drive = Drive(
        executable: executable, bucket: bucket, paths: paths,
        service: MountService(executable: executable, helperDirectory: helpers, paths: paths), connection: connection
    )
    await resources.track(drive)
    return drive
}

func withRclone(connection: Connection, _ body: (Drive) async throws -> Void) async throws {
    let executable = try await rcloneExecutable.value
    try await withFixture { resources in
        let drive = await makeDrive(executable: executable, bucket: resources.root, resources: resources, connection: connection)
        try await body(drive)
    }
}

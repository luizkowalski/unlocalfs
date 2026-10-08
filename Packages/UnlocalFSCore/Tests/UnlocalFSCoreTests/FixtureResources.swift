import Darwin
import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

actor FixtureResources {
    private struct Launch {
        let log: URL
        let offset: UInt64
    }

    let root: URL
    private var processes: [Process] = []
    private var launches: [pid_t: Launch] = [:]
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
        let offset = try log.seekToEnd()
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
        launches[process.processIdentifier] = Launch(log: url, offset: offset)
        return process
    }

    func output(of process: Process) throws -> String {
        guard let launch = launches[process.processIdentifier] else { throw AppError("Process was not started by this fixture") }
        return String(decoding: try Data(contentsOf: launch.log).dropFirst(Int(launch.offset)), as: UTF8.self)
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

private actor Slots {
    private var free: Int
    private var waiting: [CheckedContinuation<Void, Never>] = []

    init(width: Int) { free = width }

    func acquire() async {
        if free > 0 {
            free -= 1
        } else {
            await withCheckedContinuation { waiting.append($0) }
        }
    }

    func release() {
        if waiting.isEmpty {
            free += 1
        } else {
            waiting.removeFirst().resume()
        }
    }
}

private let slots = Slots(width: 3)

func withFixture(deadline: Duration = .seconds(180), _ body: (FixtureResources) async throws -> Void) async throws {
    await slots.acquire()
    do {
        try await runFixture(deadline: deadline, body)
    } catch {
        await slots.release()
        throw error
    }
    await slots.release()
}

private func runFixture(deadline: Duration, _ body: (FixtureResources) async throws -> Void) async throws {
    let resources = try FixtureResources()
    do {
        try await withDeadline(deadline) { try await body(resources) }
    } catch {
        do { try await Task.detached { try await resources.cleanup() }.value } catch { Issue.record(error) }
        throw error
    }
    try await Task.detached { try await resources.cleanup() }.value
    try FileManager.default.removeItem(at: resources.root)
}

private func withDeadline(_ limit: Duration, _ body: () async throws -> Void) async throws {
    try await withoutActuallyEscaping(body) { body in
        nonisolated(unsafe) let work = body
        try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await work()
                return true
            }
            group.addTask {
                try await Task.sleep(for: limit)
                return false
            }
            let finished = try await group.next()
            group.cancelAll()
            if finished == false { throw AppError("Fixture exceeded \(limit)") }
        }
    }
}

func requireReady(_ process: Process, in resources: FixtureResources, _ probe: () async throws -> Void) async throws {
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
        let output = (try? await resources.output(of: process)) ?? ""
        throw AppError("Fixture readiness failed: \(error)\nLast probe: \(String(describing: lastFailure))\n\(output)")
    }
}

@discardableResult
func requireOutput(
    of process: Process, in resources: FixtureResources, matching pattern: Regex<(Substring, Substring)>
) async throws -> String {
    var captured = ""
    try await requireReady(process, in: resources) {
        guard let match = try await resources.output(of: process).firstMatch(of: pattern) else {
            throw AppError("No output matching \(pattern) yet")
        }
        captured = String(match.1)
    }
    return captured
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

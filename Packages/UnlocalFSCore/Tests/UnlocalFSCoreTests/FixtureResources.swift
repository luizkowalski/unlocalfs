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

@discardableResult
func requireOutput(
    of process: Process, in resources: FixtureResources, matching pattern: Regex<(Substring, Substring)>
) async throws -> String {
    var captured: Substring?
    do {
        try await waitUntil {
            captured = try await resources.output(of: process).firstMatch(of: pattern)?.1
            guard captured != nil || process.isRunning else { throw AppError("Fixture process exited with status \(process.terminationStatus)") }
            return captured != nil
        }
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        throw AppError("Fixture readiness failed: \(error)\n\((try? await resources.output(of: process)) ?? "")")
    }
    return String(try #require(captured))
}

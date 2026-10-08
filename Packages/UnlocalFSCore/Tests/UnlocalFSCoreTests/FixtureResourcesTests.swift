import Darwin
import Foundation
import Testing

@Suite(.timeLimit(.minutes(1))) struct FixtureResourcesTests {
    @Test func setupFailureStopsAlreadyStartedProcesses() async throws {
        var started: Process?
        var root: URL?
        await #expect(throws: (any Error).self) {
            try await withFixture { resources in
                root = resources.root
                started = try await resources.start(URL(filePath: "/bin/sleep"), arguments: ["3600"], log: "sleep.log")
                _ = try await resources.start(resources.root.appending(path: "missing"), arguments: [], log: "missing.log")
            }
        }
        let process = try #require(started)
        #expect(!process.isRunning)
        #expect(kill(process.processIdentifier, 0) == -1 && errno == ESRCH)
        let retained = try #require(root)
        #expect(FileManager.default.fileExists(atPath: retained.appending(path: "sleep.log").path))
        try FileManager.default.removeItem(at: retained)
    }

    @Test func successfulScopeStopsProcessesAndRemovesItsDirectory() async throws {
        var started: Process?
        var root: URL?
        try await withFixture { resources in
            root = resources.root
            started = try await resources.start(URL(filePath: "/bin/sleep"), arguments: ["3600"], log: "sleep.log")
        }
        #expect(try #require(started).isRunning == false)
        #expect(try !FileManager.default.fileExists(atPath: #require(root).path))
    }

    @Test(arguments: [false, true])
    func cancellationStillWaitsForProcessCleanup(duringReadiness: Bool) async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: (Process, URL).self)
        let task = Task {
            defer { continuation.finish() }
            try await withFixture { resources in
                let process = try await resources.start(URL(filePath: "/bin/sleep"), arguments: ["3600"], log: "sleep.log")
                let suspend = {
                    continuation.yield((process, resources.root))
                    try await Task.sleep(for: .seconds(3600))
                }
                if duringReadiness {
                    try await requireReady(process, log: resources.root.appending(path: "sleep.log"), suspend)
                } else {
                    try await suspend()
                }
            }
        }
        var iterator = stream.makeAsyncIterator()
        let (process, root) = try #require(await iterator.next())
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(!process.isRunning)
        #expect(kill(process.processIdentifier, 0) == -1 && errno == ESRCH)
        try FileManager.default.removeItem(at: root)
    }

    @Test func cleanupStopsAProcessThatIgnoresTermination() async throws {
        var started: Process?
        try await withFixture { resources in
            let ready = resources.root.appending(path: "ready")
            started = try await resources.start(URL(filePath: "/bin/sh"), arguments: [
                "-c", "trap '' TERM; touch '\(ready.path)'; exec /bin/sleep 3600"
            ], log: "sleep.log")
            try await waitUntil { FileManager.default.fileExists(atPath: ready.path) }
        }
        let process = try #require(started)
        #expect(!process.isRunning)
        #expect(kill(process.processIdentifier, 0) == -1 && errno == ESRCH)
    }
    @Test func restartingAProcessKeepsItsEarlierLogOutput() async throws {
        var output = ""
        try await withFixture { resources in
            let first = try await resources.start(URL(filePath: "/usr/bin/printf"), arguments: ["first\n"], log: "server.log")
            try await waitUntil { !first.isRunning }
            let second = try await resources.start(URL(filePath: "/usr/bin/printf"), arguments: ["second\n"], log: "server.log")
            try await waitUntil { !second.isRunning }
            output = try String(contentsOf: resources.root.appending(path: "server.log"), encoding: .utf8)
        }
        #expect(output == "first\nsecond\n")
    }

}

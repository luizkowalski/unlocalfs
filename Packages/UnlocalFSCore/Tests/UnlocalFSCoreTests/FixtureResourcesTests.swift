import Darwin
import Foundation
import Testing
import UnlocalFSDomain

@Suite struct FixtureResourcesTests {
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
                    try await requireReady(process, in: resources, suspend)
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
        var restarted = ""
        try await withFixture { resources in
            let first = try await resources.start(URL(filePath: "/usr/bin/printf"), arguments: ["first\n"], log: "server.log")
            try await waitUntil { !first.isRunning }
            let second = try await resources.start(URL(filePath: "/usr/bin/printf"), arguments: ["second\n"], log: "server.log")
            try await waitUntil { !second.isRunning }
            output = try String(contentsOf: resources.root.appending(path: "server.log"), encoding: .utf8)
            restarted = try await resources.output(of: second)
        }
        #expect(output == "first\nsecond\n")
        #expect(restarted == "second\n")
    }

    @Test func fixtureThatOutlivesItsDeadlineFailsAndStopsItsProcesses() async throws {
        var started: Process?
        var root: URL?
        await #expect {
            try await withFixture(deadline: .seconds(1)) { resources in
                root = resources.root
                started = try await resources.start(URL(filePath: "/bin/sleep"), arguments: ["3600"], log: "sleep.log")
                try await Task.sleep(for: .seconds(3600))
            }
        } throws: { ($0 as? AppError)?.localizedDescription.contains("exceeded") == true }
        let process = try #require(started)
        #expect(!process.isRunning)
        try FileManager.default.removeItem(at: #require(root))
    }

    @Test func fixturesRunThreeAtATime() async throws {
        let fixtures = RunningFixtures()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<6 {
                group.addTask {
                    try await withFixture { _ in
                        await fixtures.enter()
                        try await Task.sleep(for: .milliseconds(300))
                        await fixtures.leave()
                    }
                }
            }
            try await group.waitForAll()
        }
        #expect(await fixtures.peak <= 3)
    }
}

private actor RunningFixtures {
    private var running = 0
    private(set) var peak = 0

    func enter() {
        running += 1
        peak = max(peak, running)
    }

    func leave() { running -= 1 }
}

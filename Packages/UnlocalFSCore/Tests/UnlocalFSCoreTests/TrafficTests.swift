import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
import UnlocalFSTestSupport

@Suite struct TrafficTests {
    private let busyStats = """
    {"bytes":12000,"serverSideCopyBytes":0,"serverSideMoveBytes":2000,"transferring":[
        {"name":"video.mov","size":9000,"bytes":4000,"srcFs":"/cache","dstFs":":s3:bucket"},
        {"name":"renamed.mov","size":2000,"bytes":2000,"srcFs":":s3:bucket","dstFs":":s3:bucket"}
    ]}
    """

    @Test func networkTrafficStaysUnsavedUntilDisconnectSavesItForToday() async throws {
        try await withRclone(stats: busyStats) { drives, connection, _ in
            let status = await drives.service.status(connection)
            let beforeDisconnect = try drives.traffic.traffic(in: today...today)
            #expect(status.unsavedTraffic == Traffic(upload: 4_000, download: 6_000))
            #expect(beforeDisconnect.isEmpty)

            try await drives.service.unmount(connection)
            #expect(try drives.traffic.traffic(in: today...today).map(\.traffic) == [Traffic(upload: 4_000, download: 6_000)])
        }
    }

    @Test func brokenTrafficDatabaseNeverBlocksStatusOrDisconnect() async throws {
        try await withRclone(stats: busyStats) { drives, connection, _ in
            let broken = TrafficStore(url: URL(filePath: "/dev/null/traffic.sqlite"))
            let service = MountService(executable: drives.root.appending(path: "rclone"), helperDirectory: drives.root, paths: drives.paths, traffic: broken)
            let status = await service.status(connection)
            #expect(status.isRunning && status.controlError == nil)
            try await service.unmount(connection)
            #expect(await !service.status(connection).isActive)
        }
    }

    @Test func relaunchCountsOnlyWhatMovedSinceTheLastSave() async throws {
        let stats = #"{"bytes":12000,"serverSideCopyBytes":0,"serverSideMoveBytes":0,"transferring":[]}"#
        let transferred = """
        {"transferred":[{"name":"old.mov","size":1500,"bytes":1500,"error":"","completed_at":"2026-01-01T10:00:00Z","srcFs":"/cache","dstFs":":s3:bucket"}]}
        """
        try await withRclone(stats: stats, transferred: transferred) { drives, connection, rclone in
            let earlier = TrafficCheckpoint(process: rclone, network: 10_000, savedAt: .now - 60)
            try drives.traffic.save(TrafficSave(day: today, traffic: Traffic(), checkpoint: earlier), for: connection)
            #expect(await drives.service.status(connection).unsavedTraffic == Traffic(upload: 0, download: 2_000))
        }
    }

    @Test func newRcloneProcessCountsFromZero() async throws {
        let stats = #"{"bytes":3000,"serverSideCopyBytes":0,"serverSideMoveBytes":0,"transferring":[]}"#
        try await withRclone(stats: stats) { drives, connection, _ in
            let previous = RcloneProcess(pid: 1, startedAt: Date(timeIntervalSince1970: 0))
            let earlier = TrafficCheckpoint(process: previous, network: 50_000, savedAt: .now - 60)
            try drives.traffic.save(TrafficSave(day: today, traffic: Traffic(), checkpoint: earlier), for: connection)
            #expect(await drives.service.status(connection).unsavedTraffic == Traffic(upload: 0, download: 3_000))
        }
    }

    @Test func olderSnapshotDoesNotCountFinishedUploadsAgain() throws {
        var tally = UploadTally(process: RcloneProcess(pid: 1, startedAt: .distantPast))
        let newer = try snapshot(network: 5_000, uploads: ["a.mov", "b.mov"])
        let older = try snapshot(network: 3_000, uploads: ["a.mov"])

        #expect(tally.read(newer) == 2_000)
        #expect(tally.read(older) == 2_000)
        #expect(tally.read(newer) == 2_000)
    }

    private func snapshot(network: Int64, uploads: [String]) throws -> ControlSnapshot {
        let finished = uploads.map {
            #"{"name":"\#($0)","size":1000,"bytes":1000,"error":"","completed_at":"2026-10-19T10:00:00Z","srcFs":"/cache","dstFs":":s3:bucket"}"#
        }
        let batch = statusBatch(
            cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0"#,
            stats: #"{"bytes":\#(network),"serverSideCopyBytes":0,"serverSideMoveBytes":0}"#,
            transferred: #"{"transferred":[\#(finished.joined(separator: ","))]}"#
        )
        return try JSONDecoder().decode(ControlSnapshot.self, from: Data(batch.utf8))
    }
}

private var today: TrafficDay { TrafficDay(.now, calendar: .current) }

private func withRclone(
    stats: String, transferred: String = #"{"transferred":[]}"#, operation: (StubbedDrives, Connection, RcloneProcess) async throws -> Void
) async throws {
    let drives = try StubbedDrives("traffic")
    defer { drives.remove() }
    let connection = Connection.s3()
    let rclone = Process()
    rclone.executableURL = URL(filePath: "/bin/sleep")
    rclone.arguments = ["60"]
    try rclone.run()
    defer { rclone.terminate() }
    try String(rclone.processIdentifier).write(to: drives.paths.pidFile(connection), atomically: true, encoding: .utf8)
    let socket = drives.paths.socket(connection)
    let batch = statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0"#, stats: stats, transferred: transferred)
    let server = try ControlServer(at: socket) { request in
        switch request.method {
        case "job/list": return #"{"runningIds":[]}"#
        case "core/quit":
            rclone.terminate()
            rclone.waitUntilExit()
            try FileManager.default.removeItem(at: socket)
            return "{}"
        default: return batch
        }
    }
    defer { server.stop() }
    let process = try #require(MountService.process(pid: rclone.processIdentifier))
    try await operation(drives, connection, process)
}

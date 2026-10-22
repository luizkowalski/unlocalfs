import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
import UnlocalFSTestSupport

@Suite struct TrafficTests {
    @Test func networkTrafficStaysUnsavedUntilDisconnectSavesItForToday() async throws {
        let start = reply(stats: busyStats(bytes: 12_000))
        let later = reply(stats: busyStats(bytes: 14_000))
        try await withRclone(replying: start, start, later) { drives, connection, _ in
            let status = await drives.service.status(connection)
            let beforeDisconnect = try drives.traffic.traffic(in: today...today)
            #expect(status.unsavedTraffic == Traffic(upload: 4_000, download: 6_000))
            #expect(beforeDisconnect.isEmpty)

            try await drives.service.unmount(connection)
            #expect(try drives.traffic.traffic(in: today...today).map(\.traffic) == [Traffic(upload: 4_000, download: 8_000)])
        }
    }

    @Test func brokenTrafficDatabaseNeverBlocksStatusOrDisconnect() async throws {
        try await withRclone(replying: reply(stats: busyStats())) { drives, connection, _ in
            let broken = TrafficStore(url: URL(filePath: "/dev/null/traffic.sqlite"))
            let service = MountService(executable: drives.root.appending(path: "rclone"), helperDirectory: drives.root, paths: drives.paths, traffic: broken)
            let status = await service.status(connection)
            #expect(status.isRunning && status.controlError == nil)
            try await service.unmount(connection)
            #expect(await !service.status(connection).isActive)
        }
    }

    @Test func relaunchCountsOnlyWhatMovedSinceTheLastSave() async throws {
        try await withRclone(replying: reply(stats: counters(bytes: 12_000), transferred: finished("old.mov"))) { drives, connection, rclone in
            let earlier = TrafficCheckpoint(process: rclone, network: 10_000, savedAt: .now - 60)
            try drives.traffic.save(TrafficSave(day: today, traffic: Traffic(), checkpoint: earlier), for: connection)
            #expect(await drives.service.status(connection).unsavedTraffic == Traffic(upload: 0, download: 2_000))
        }
    }

    @Test func olderSnapshotDoesNotCountFinishedUploadsAgain() async throws {
        let newer = reply(stats: counters(bytes: 5_000), transferred: finished("a.mov", "b.mov"))
        let older = reply(stats: counters(bytes: 3_000), transferred: finished("a.mov"))
        try await withRclone(replying: newer, older, newer) { drives, connection, _ in
            for _ in 0..<3 {
                #expect(await drives.service.status(connection).unsavedTraffic == Traffic(upload: 2_000, download: 3_000))
            }
        }
    }

    @Test func uploadFinishingDuringAReadCountsOnce() async throws {
        let transferring = #"{"name":"video.mov","size":1000,"bytes":1000,"srcFs":"/cache","dstFs":":s3:bucket"}"#
        let finishing = reply(stats: counters(bytes: 10_000, transferring: transferring), transferred: finished("video.mov"))
        try await withRclone(replying: finishing) { drives, connection, _ in
            #expect(await drives.service.status(connection).unsavedTraffic == Traffic(upload: 1_000, download: 9_000))
        }
    }

    private func busyStats(bytes: Int = 12_000) -> String {
        """
        {"bytes":\(bytes),"serverSideCopyBytes":0,"serverSideMoveBytes":2000,"transferring":[
            {"name":"video.mov","size":9000,"bytes":4000,"srcFs":"/cache","dstFs":":s3:bucket"},
            {"name":"renamed.mov","size":2000,"bytes":2000,"srcFs":":s3:bucket","dstFs":":s3:bucket"}
        ]}
        """
    }
}

private var today: TrafficDay { TrafficDay(.now, calendar: .current) }

private func counters(bytes: Int, transferring: String = "") -> String {
    #"{"bytes":\#(bytes),"serverSideCopyBytes":0,"serverSideMoveBytes":0,"transferring":[\#(transferring)]}"#
}

private func finished(_ names: String...) -> String {
    let transfers = names.map {
        #"{"name":"\#($0)","size":1000,"bytes":1000,"error":"","completed_at":"2026-10-19T10:00:00Z","srcFs":"/cache","dstFs":":s3:bucket"}"#
    }
    return #"{"transferred":[\#(transfers.joined(separator: ","))]}"#
}

private func reply(stats: String, transferred: String = #"{"transferred":[]}"#) -> String {
    statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0"#, stats: stats, transferred: transferred)
}

private func withRclone(
    replying replies: String..., operation: (StubbedDrives, Connection, RcloneProcess) async throws -> Void
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
    let pending = Mutex(replies)
    let server = try ControlServer(at: socket) { request in
        switch request.method {
        case "job/list": return #"{"runningIds":[]}"#
        case "core/quit":
            rclone.terminate()
            rclone.waitUntilExit()
            try FileManager.default.removeItem(at: socket)
            return "{}"
        default: return pending.withLock { $0.count > 1 ? $0.removeFirst() : $0[0] }
        }
    }
    defer { server.stop() }
    let process = try #require(MountService.process(pid: rclone.processIdentifier))
    try await operation(drives, connection, process)
}

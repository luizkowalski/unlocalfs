import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
import UnlocalFSTestSupport

struct TrafficTests {
    @Test func networkTrafficStaysUnsavedUntilDisconnectSavesItForToday() async throws {
        try await withRclone(replying: reply(stats: busyStats(bytes: 12000))) { drives, connection, _, batch in
            let status = await drives.service.status(connection)
            let beforeDisconnect = try drives.traffic.traffic(in: today ... today)
            #expect(status.unsavedTraffic == Traffic(upload: 4000, download: 6000))
            #expect(beforeDisconnect.isEmpty)

            batch.set(reply(stats: busyStats(bytes: 14000)))
            try await drives.service.unmount(connection)
            #expect(try drives.traffic.traffic(in: today ... today).map(\.traffic) == [Traffic(upload: 4000, download: 8000)])
        }
    }

    @Test func brokenTrafficDatabaseNeverBlocksStatusOrDisconnect() async throws {
        try await withRclone(replying: reply(stats: busyStats())) { drives, connection, _, _ in
            let broken = TrafficStore(url: URL(filePath: "/dev/null/traffic.sqlite"))
            let service = MountService(executable: drives.root.appending(path: "rclone"), helperDirectory: drives.root, paths: drives.paths, traffic: broken, googleClient: .test)
            let status = await service.status(connection)
            #expect(status.isRunning && status.controlError == nil)
            try await service.unmount(connection)
            #expect(await !service.status(connection).isActive)
        }
    }

    @Test func relaunchCountsOnlyWhatMovedSinceTheLastSave() async throws {
        try await withRclone(replying: reply(stats: counters(bytes: 12000), transferred: finished("old.mov"))) { drives, connection, rclone, _ in
            let earlier = TrafficCheckpoint(process: rclone, network: 10000, savedAt: .now - 60)
            try drives.traffic.save(TrafficSave(day: today, traffic: Traffic(), checkpoint: earlier), for: connection)
            #expect(await drives.service.status(connection).unsavedTraffic == Traffic(upload: 0, download: 2000))
        }
    }

    @Test func olderSnapshotDoesNotCountFinishedUploadsAgain() async throws {
        let newer = reply(stats: counters(bytes: 5000), transferred: finished("a.mov", "b.mov"))
        let older = reply(stats: counters(bytes: 3000), transferred: finished("a.mov"))
        try await withRclone(replying: newer) { drives, connection, _, batch in
            for snapshot in [newer, older, newer] {
                batch.set(snapshot)
                #expect(await drives.service.status(connection).unsavedTraffic == Traffic(upload: 2000, download: 3000))
            }
        }
    }

    @Test func uploadFinishingDuringAReadCountsOnce() async throws {
        let transferring = #"{"name":"video.mov","size":1000,"bytes":1000,"srcFs":"/cache","dstFs":":s3:bucket"}"#
        let finishing = reply(stats: counters(bytes: 10000, transferring: transferring), transferred: finished("video.mov"))
        try await withRclone(replying: finishing) { drives, connection, _, _ in
            #expect(await drives.service.status(connection).unsavedTraffic == Traffic(upload: 1000, download: 9000))
        }
    }

    private func busyStats(bytes: Int = 12000) -> String {
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
    statusBatch(stats: stats, transferred: transferred)
}

private func withRclone(
    replying initial: String, operation: (StubbedDrives, Connection, RcloneProcess, BatchReply) async throws -> Void,
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
    let batch = BatchReply(initial)
    let server = try ControlServer(at: socket) { request in
        switch request.method {
        case "job/list": return #"{"runningIds":[]}"#
        case "core/quit":
            rclone.terminate()
            rclone.waitUntilExit()
            try FileManager.default.removeItem(at: socket)
            return "{}"
        default: return batch.current
        }
    }
    defer { server.stop() }
    let process = try #require(MountService.process(pid: rclone.processIdentifier))
    try await operation(drives, connection, process, batch)
}

private final class BatchReply: Sendable {
    private let reply: Mutex<String>

    init(_ reply: String) { self.reply = Mutex(reply) }

    var current: String { reply.withLock { $0 } }

    func set(_ reply: String) { self.reply.withLock { $0 = reply } }
}

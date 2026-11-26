import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
import UnlocalFSTestSupport

@Suite(.timeLimit(.minutes(1)))
struct FileVersionsTests {
    @Test func restoreCopiesTheVersionOnTheServerAndADisconnectWaitsForIt() async throws {
        let bucket = VersionedBucket(["report.txt", "report-v2026-11-02-140301-123.txt"])
        let copying = Mutex(false)
        try await withControl { _, _ in
            { request in
                let held = copying.withLock { $0 }
                switch request.method {
                case "job/list": return #"{"runningIds":[]}"#
                case "job/status" where held: return #"{"finished":false,"success":false,"error":""}"#
                default: return try await bucket.respond(request)
                }
            }
        } operation: { service, connection in
            try await FileManager.default.createDirectory(at: service.paths.mount(connection), withIntermediateDirectories: true)
            let old = try #require(try await service.versions(in: "", of: connection).first { !$0.isCurrent })
            try await service.restore(old, asCopy: false, in: connection)
            let copy = try #require(bucket.requests.last { $0["dstRemote"] as? String == "report.txt" })
            #expect(copy["srcFs"] as? String == "unlocalfs-s3,versions=true:my-bucket")
            #expect(copy["dstFs"] as? String == "unlocalfs-s3,versions=true:my-bucket")
            try await service.restore(old, asCopy: true, in: connection)
            #expect(bucket.requests.last { $0["dstRemote"] != nil }?["dstRemote"] as? String == "report copy.txt")

            copying.withLock { $0 = true }
            let restore = Task { try await service.restore(old, asCopy: false, in: connection) }
            try await waitUntil { bucket.requests.count { $0["dstRemote"] != nil } == 3 }
            await #expect { try await service.unmount(connection) } throws: { error in
                error.localizedDescription == String(localized: .copyInProgress)
            }
            restore.cancel()
        }
    }

    @Test func previewDownloadsTheVersionUnderItsFileName() async throws {
        let bucket = VersionedBucket(["report-v2026-11-02-140301-123.txt"])
        try await withControl { _, _ in bucket.respond } operation: { service, connection in
            let old = try #require(try await service.versions(in: "", of: connection).first)
            let file = try await service.preview(old, in: connection)
            #expect(file.lastPathComponent == "report.txt")
            let copy = try #require(bucket.requests.last { $0["dstRemote"] != nil })
            #expect(copy["dstFs"] as? String == file.deletingLastPathComponent().path)
            service.discardPreview(file)
            #expect(!FileManager.default.fileExists(atPath: file.deletingLastPathComponent().path))
        }
    }

    @Test func cancelledListingStopsItsJob() async throws {
        let waiting = Mutex(false)
        let stopped = Mutex(false)
        try await withControl { _, _ in
            { request in
                switch request.method {
                case "operations/list": return #"{"jobid":4}"#
                case "job/stop":
                    stopped.withLock { $0 = request.parameter("jobid") == "4" }
                    return "{}"
                default:
                    waiting.withLock { $0 = true }
                    return #"{"finished":false,"success":false,"error":""}"#
                }
            }
        } operation: { service, connection in
            let listing = Task { try await service.versions(in: "", of: connection) }
            try await waitUntil { waiting.withLock { $0 } }
            listing.cancel()
            _ = await listing.result
            try await waitUntil { stopped.withLock { $0 } }
        }
    }
}

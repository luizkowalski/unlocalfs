import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
import UnlocalFSTestSupport

@Suite(.timeLimit(.minutes(1)))
struct FileVersionsTests {
    @Test(arguments: [
        (false, "unlocalfs-s3,versions=true:my-bucket"),
        (true, "unlocalfs,remote='unlocalfs-s3,versions=true:my-bucket':"),
    ])
    func listingReadsTheVersionedRemoteWithoutHeadRequests(encrypted: Bool, versionsFs: String) async throws {
        let bucket = VersionedBucket(["sub/report.txt", "sub/report-v2026-11-02-140301-123.txt"])
        try await withControl(connection: .s3 { $0.encrypted = encrypted }) { _, _ in bucket.respond } operation: { service, connection in
            let versions = try await service.versions(in: "sub", of: connection)
            #expect(versions.map(\.path) == ["sub/report.txt", "sub/report-v2026-11-02-140301-123.txt"])
            let request = try #require(bucket.requests.first { $0["fs"] as? String == versionsFs })
            #expect(request["remote"] as? String == "sub")
            #expect((request["opt"] as? [String: Bool])?["noMimeType"] == true)
            #expect((request["_config"] as? [String: Bool])?["UseServerModTime"] == true)
        }
    }

    @Test func restoreCopiesTheVersionOnTheServerOverTheFileOrNextToIt() async throws {
        let bucket = VersionedBucket(["report.txt", "report-v2026-11-02-140301-123.txt"])
        try await withControl { _, _ in bucket.respond } operation: { service, connection in
            try await FileManager.default.createDirectory(at: service.paths.mount(connection), withIntermediateDirectories: true)
            let old = try #require(try await service.versions(in: "", of: connection).first { !$0.isCurrent })
            try await service.restore(old, asCopy: false, in: connection)
            let copy = try #require(bucket.requests.last { $0["dstRemote"] as? String == "report.txt" })
            #expect(copy["srcFs"] as? String == "unlocalfs-s3,versions=true:my-bucket")
            #expect(copy["dstFs"] as? String == "unlocalfs-s3,versions=true:my-bucket")
            #expect(copy["_group"] as? String == "duplicate")
            try await service.restore(old, asCopy: true, in: connection)
            #expect(bucket.requests.last { $0["dstRemote"] != nil }?["dstRemote"] as? String == "report copy.txt")
        }
    }

    @Test func restoreRefusesAFileThatWaitsToUpload() async throws {
        let bucket = VersionedBucket(["report.txt", "report-v2026-11-02-140301-123.txt"], queue: "report.txt")
        try await withControl { _, _ in bucket.respond } operation: { service, connection in
            let old = try #require(try await service.versions(in: "", of: connection).first { !$0.isCurrent })
            await #expect { try await service.restore(old, asCopy: false, in: connection) } throws: { error in
                error.localizedDescription == String(localized: .restoreFileStillUploading)
            }
            #expect(!bucket.requests.contains { $0["dstRemote"] != nil })
        }
    }

    @Test(arguments: [
        ("Enabled", BucketVersioning.enabled), ("Suspended", .suspended), ("Unversioned", .off), ("", .unknown),
    ])
    func versioningReadsTheBucketState(reply: String, state: BucketVersioning) async throws {
        try await withControl { _, _ in
            { request in
                guard request.method == "backend/command", !reply.isEmpty else { throw ControlFailure("AccessDenied") }
                return #"{"result":"\#(reply)"}"#
            }
        } operation: { service, connection in
            #expect(await service.versioning(of: connection) == state)
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

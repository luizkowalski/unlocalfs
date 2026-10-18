import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSTestSupport

@Suite struct ActivityTests {
    @Test(arguments: [(0, false, FileActivity.State.queued), (1, true, .uploading)])
    func queuedUploadsShowTheirPathSizeAndState(tries: Int, uploading: Bool, state: FileActivity.State) async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[{"name":"photos/holiday.jpg","id":1,"size":2048,"expiry":4,"tries":\(tries),"delay":5,"uploading":\(uploading)}]}
        """)
        let item = try #require(activity.first)
        #expect(activity.count == 1)
        #expect(item.path == "photos/holiday.jpg")
        #expect(item.size == 2048)
        #expect(item.state == state)
        #expect(item.bytesTransferred == nil)
        #expect(item.uploadError == nil)
    }

    @Test func failedUploadsShowTheirOwnLatestUploadErrorAndNextAttempt() async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[
            {"name":"denied.jpg","id":1,"size":10,"expiry":120,"tries":2,"delay":10,"uploading":false},
            {"name":"unknown.jpg","id":2,"size":10,"expiry":30,"tries":2,"delay":10,"uploading":false},
            {"name":"read.jpg","id":3,"size":10,"expiry":30,"tries":2,"delay":10,"uploading":false},
            {"name":"twice.jpg","id":4,"size":10,"expiry":30,"tries":3,"delay":20,"uploading":false},
            {"name":"again.mov","id":5,"size":1000,"expiry":-1,"tries":3,"delay":20,"uploading":true}
        ]}
        """, transferred: """
        {"transferred":[
            {"name":"denied.jpg","size":10,"bytes":0,"error":"AccessDenied: Access Denied","completed_at":"2026-10-11T16:10:36+02:00","dstFs":":s3:bucket"},
            {"name":"read.jpg","size":10,"bytes":0,"error":"read failed","completed_at":"2026-10-11T16:10:36+02:00","srcFs":":s3:bucket"},
            {"name":"twice.jpg","size":10,"bytes":0,"error":"second error","completed_at":"2026-10-11T16:10:40+02:00","dstFs":":s3:bucket"},
            {"name":"twice.jpg","size":10,"bytes":0,"error":"first error","completed_at":"2026-10-11T16:10:30+02:00","dstFs":":s3:bucket"},
            {"name":"twice.jpg","size":10,"bytes":10,"error":"","completed_at":"2026-10-11T16:10:20+02:00","dstFs":":s3:bucket"},
            {"name":"again.mov","size":1000,"bytes":0,"error":"AccessDenied: Access Denied","completed_at":"2026-10-11T16:10:36+02:00","dstFs":":s3:bucket"}
        ]}
        """)
        let byPath = Dictionary(uniqueKeysWithValues: activity.map { ($0.path, $0) })
        #expect(activity.count == 5)
        #expect(byPath.mapValues(\.uploadError) == [
            "denied.jpg": "AccessDenied: Access Denied", "unknown.jpg": nil, "read.jpg": nil,
            "twice.jpg": "second error", "again.mov": "AccessDenied: Access Denied",
        ])
        guard case .failed(let nextAttempt) = byPath["denied.jpg"]?.state else {
            Issue.record("Expected a failed upload")
            return
        }
        #expect(abs(nextAttempt.timeIntervalSinceNow - 120) < 5)
        #expect(byPath["again.mov"]?.state == .uploading)
    }

    @Test func uploadsUseUploadProgressWhenTheSameFileIsDownloading() async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[{"name":"video.mov","id":1,"size":1000,"expiry":-2,"tries":1,"delay":5,"uploading":true}]}
        """, stats: """
        {"transferring":[
            {"name":"video.mov","size":1000,"bytes":100,"srcFs":":s3:bucket"},
            {"name":"video.mov","size":1000,"bytes":600,"speedAvg":250000.5,"srcFs":"/cache","dstFs":":s3:bucket"}
        ]}
        """)
        #expect(activity.count == 2)
        let upload = try #require(activity.first { $0.state == .uploading })
        #expect(upload.bytesTransferred == 600)
        #expect(upload.bytesPerSecond == 250000.5)
        let download = try #require(activity.first { $0.state == .downloading })
        #expect(download.bytesTransferred == 100)
        #expect(download.bytesPerSecond == nil)
        #expect(download.id != upload.id)
    }

    @Test func queuedUploadsHaveNoSpeedEvenWhenATransferHasTheirName() async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[{"name":"video.mov","id":1,"size":1000,"expiry":4,"tries":0,"delay":5,"uploading":false}]}
        """, stats: """
        {"transferring":[{"name":"video.mov","size":1000,"bytes":600,"speedAvg":250000,"srcFs":"/cache","dstFs":":s3:bucket"}]}
        """)
        #expect(activity.map(\.bytesPerSecond) == [nil])
    }

    @Test func downloadsReportTheirSpeed() async throws {
        let activity = try await fetchActivity(queue: #"{"queue":[]}"#, stats: """
        {"transferring":[{"name":"movie.mkv","size":5000,"bytes":100,"speedAvg":4096,"srcFs":":s3:bucket"}]}
        """)
        #expect(activity.map(\.bytesPerSecond) == [4096])
    }

    @Test func finishedTransfersShowOnceUnlessTheFileMovesAgain() async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[{"name":"video.mov","id":1,"size":1000,"expiry":4,"tries":0,"delay":5,"uploading":false}]}
        """, transferred: """
        {"transferred":[
            {"name":"photo.jpg","size":20,"bytes":20,"error":"","completed_at":"2026-10-11T16:10:36.750335+02:00","dstFs":":s3:bucket"},
            {"name":"photo.jpg","size":10,"bytes":10,"error":"","completed_at":"2026-10-11T16:10:35.1+02:00","dstFs":":s3:bucket"},
            {"name":"video.mov","size":1000,"bytes":1000,"error":"","completed_at":"2026-10-11T16:10:36+02:00","dstFs":":s3:bucket"},
            {"name":"denied.txt","size":5,"bytes":0,"error":"Access Denied","completed_at":"2026-10-11T16:10:36+02:00","dstFs":":s3:bucket"},
            {"name":"movie.mkv","size":5000,"bytes":5000,"error":"","completed_at":"2026-10-11T16:10:37+02:00","srcFs":":s3:bucket"},
            {"name":"preview.mov","size":9000,"bytes":100,"error":"","completed_at":"2026-10-11T16:10:37+02:00","srcFs":":s3:bucket"}
        ]}
        """)
        let uploaded = try Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse("2026-10-11T14:10:36.750335Z")
        let downloaded = try Date.ISO8601FormatStyle().parse("2026-10-11T14:10:37Z")
        #expect(Set(activity.map(\.id)) == ["upload:video.mov", "upload:photo.jpg", "download:movie.mkv"])
        #expect(activity.first { $0.path == "video.mov" }?.state == .queued)
        #expect(activity.first { $0.path == "photo.jpg" } == FileActivity(path: "photo.jpg", size: 20, state: .uploaded(uploaded), bytesTransferred: 20))
        #expect(activity.first { $0.path == "movie.mkv" } == FileActivity(path: "movie.mkv", size: 5000, state: .downloaded(downloaded), bytesTransferred: 5000))
    }
}

private func fetchActivity(queue: String, stats: String = "{}", transferred: String? = nil) async throws -> [FileActivity] {
    let drives = try StubbedDrives("activity")
    defer { drives.remove() }
    let connection = Connection.s3()
    let batch = statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0"#, queue: queue, stats: stats, transferred: transferred)
    let server = try ControlServer(at: drives.paths.socket(connection)) { _ in batch }
    defer { server.stop() }
    return try await drives.service.activity(connection)
}

import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite struct ActivityTests {
    @Test(arguments: [(0, false, FileActivity.State.queued), (2, false, .retrying), (1, true, .uploading)])
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
}

private func fetchActivity(queue: String, stats: String = "{}") async throws -> [FileActivity] {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let binary = root.appendingPathComponent("rclone")
    let batch = statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"erroredFiles":0,"bytesUsed":0"#, queue: queue, stats: stats)
    try Data(batch.utf8).write(to: root.appendingPathComponent("batch.json"))
    try writeRcloneStub("cat '\(root.path)/batch.json'", to: binary)
    let paths = AppPaths(config: root, support: root, mounts: root, logs: root)
    let service = MountService(executable: binary, helperDirectory: root, paths: paths)
    return try await service.activity(fixture())
}

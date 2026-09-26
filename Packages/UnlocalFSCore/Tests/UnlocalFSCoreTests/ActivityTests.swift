import Foundation
import Testing
import UnlocalFSCore

@Suite struct ActivityTests {
    @Test func queuedUploadsShowTheirPathsAndSizes() async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[{"name":"photos/holiday.jpg","id":1,"size":2048,"expiry":4,"tries":0,"delay":5,"uploading":false}]}
        """)
        let item = try #require(activity.first)
        #expect(activity.count == 1)
        #expect(item.path == "photos/holiday.jpg")
        #expect(item.size == 2048)
        #expect(item.state == .queued)
        #expect(item.bytesTransferred == nil)
    }

    @Test func uploadsUseUploadProgressWhenTheSameFileIsDownloading() async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[{"name":"video.mov","id":1,"size":1000,"expiry":-2,"tries":1,"delay":5,"uploading":true}]}
        """, stats: """
        {"transferring":[
            {"name":"video.mov","size":1000,"bytes":100,"srcFs":":s3:bucket"},
            {"name":"video.mov","size":1000,"bytes":600,"srcFs":"/cache","dstFs":":s3:bucket"}
        ]}
        """)
        #expect(activity.count == 2)
        let upload = try #require(activity.first { $0.state == .uploading })
        #expect(upload.bytesTransferred == 600)
        let download = try #require(activity.first { $0.state == .downloading })
        #expect(download.bytesTransferred == 100)
        #expect(download.id != upload.id)
    }

    @Test func previouslyAttemptedUploadsShowWaitingForRetry() async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[{"name":"report.pdf","id":1,"size":200,"expiry":10,"tries":2,"delay":20,"uploading":false}]}
        """)
        let item = try #require(activity.first)
        #expect(item.state == .retrying)
    }

    @Test func uploadingWithoutByteStatsHasIndeterminateProgress() async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[{"name":"empty.txt","id":1,"size":0,"expiry":-1,"tries":1,"delay":5,"uploading":true}]}
        """)
        let item = try #require(activity.first)
        #expect(item.state == .uploading)
        #expect(item.bytesTransferred == nil)
    }

    @Test func activityIsSortedByPath() async throws {
        let activity = try await fetchActivity(queue: """
        {"queue":[{"name":"file10.txt","id":1,"size":1,"expiry":4,"tries":0,"delay":5,"uploading":false}]}
        """, stats: """
        {"transferring":[{"name":"file2.txt","size":1,"bytes":0,"srcFs":":s3:bucket"}]}
        """)
        #expect(activity.map(\.path) == ["file2.txt", "file10.txt"])
    }

    @Test func idleDriveHasNoActivity() async throws {
        let activity = try await fetchActivity(queue: "{\"queue\":[]}")
        #expect(activity.isEmpty)
    }

    @Test func invalidActivityIsReportedInsteadOfShowingAnIdleDrive() async {
        await #expect(throws: DecodingError.self) {
            try await fetchActivity(queue: "{}")
        }
    }
}

@discardableResult
private func fetchActivity(queue: String, stats: String = "{}") async throws -> [FileActivity] {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try Data(queue.utf8).write(to: root.appendingPathComponent("queue.json"))
    try Data(stats.utf8).write(to: root.appendingPathComponent("stats.json"))
    let binary = root.appendingPathComponent("rclone")
    let script = """
    #!/bin/sh
    case "$4" in
        vfs/queue) cat '\(root.path)/queue.json' ;;
        core/stats) cat '\(root.path)/stats.json' ;;
        *) exit 1 ;;
    esac
    """
    try script.write(to: binary, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: binary.path)
    let paths = AppPaths(config: root, support: root, mounts: root, logs: root)
    let service = MountService(executable: binary, helperDirectory: root, paths: paths)
    return try await service.activity(fixture())
}

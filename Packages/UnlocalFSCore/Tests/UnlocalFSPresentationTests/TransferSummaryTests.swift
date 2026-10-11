import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSPresentation

@Suite struct TransferSummaryTests {
    let now = Date()

    @Test func uploadsLeadWhenFilesMoveBothWays() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "video.mov", size: 1000, state: .uploading, bytesTransferred: 600, bytesPerSecond: 200),
            FileActivity(path: "clip.mov", size: 500, state: .uploading, bytesTransferred: 200, bytesPerSecond: 100),
            FileActivity(path: "photo.jpg", size: 500, state: .queued, bytesTransferred: nil),
            FileActivity(path: "notes.txt", size: 300, state: .downloading, bytesTransferred: 100, bytesPerSecond: 5000)
        ], now: now))

        #expect(summary.isUploading)
        #expect(summary.fileCount == 3)
        #expect(summary.bytesPerSecond == 300)
    }

    @Test func downloadsLeadWhenNothingUploads() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "movie.mkv", size: 7_537_000_000, state: .downloading, bytesTransferred: 2_100_000, bytesPerSecond: 4096)
        ], now: now))

        #expect(!summary.isUploading)
        #expect(summary.fileCount == 1)
        #expect(summary.bytesPerSecond == 4096)
    }

    @Test func queuedUploadsAloneHaveNoSpeed() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "photo.jpg", size: 500, state: .queued, bytesTransferred: nil)
        ], now: now))

        #expect(summary.bytesPerSecond == nil)
    }

    @Test func filesListByNameWhateverTheirState() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "file10.txt", size: 1, state: .uploading, bytesTransferred: 0),
            FileActivity(path: "b.txt", size: 1, state: .downloaded(now), bytesTransferred: 1),
            FileActivity(path: "file2.txt", size: 1, state: .queued, bytesTransferred: nil),
            FileActivity(path: "a.txt", size: 1, state: .failed(nextAttempt: .now), bytesTransferred: nil)
        ], now: now))

        #expect(summary.files.map(\.path) == ["a.txt", "b.txt", "file2.txt", "file10.txt"])
    }

    @Test func listStopsAtTenFilesAndKeepsMovingFiles() throws {
        let summary = try #require(TransferSummary((1...11).map {
            FileActivity(path: "file\($0).txt", size: 1, state: .uploaded(now), bytesTransferred: 1)
        } + [FileActivity(path: "zebra.txt", size: 1, state: .downloading, bytesTransferred: 0)], now: now))

        #expect(summary.files.count == 10)
        #expect(summary.files.last?.path == "zebra.txt")
        #expect(summary.hiddenFileCount == 2)
    }

    @Test func finishedFilesDoNotCountAsMoving() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "done.txt", size: 1, state: .uploaded(now), bytesTransferred: 1),
            FileActivity(path: "movie.mkv", size: 1, state: .downloaded(now), bytesTransferred: 1),
            FileActivity(path: "photo.jpg", size: 500, state: .queued, bytesTransferred: nil)
        ], now: now))

        #expect(summary.isUploading)
        #expect(summary.fileCount == 1)
    }

    @Test func finishedFilesShowForTenSeconds() throws {
        let recent = now.addingTimeInterval(-9.9), old = now.addingTimeInterval(-10)
        let summary = try #require(TransferSummary([
            FileActivity(path: "a.txt", size: 1, state: .uploaded(recent), bytesTransferred: 1),
            FileActivity(path: "b.txt", size: 1, state: .downloaded(recent), bytesTransferred: 1),
            FileActivity(path: "c.txt", size: 1, state: .uploaded(old), bytesTransferred: 1),
            FileActivity(path: "d.txt", size: 1, state: .downloaded(old), bytesTransferred: 1)
        ], now: now))
        #expect(summary.files.map(\.path) == ["a.txt", "b.txt"])
        #expect(summary.fileCount == 0)

        #expect(TransferSummary([FileActivity(path: "c.txt", size: 1, state: .uploaded(old), bytesTransferred: 1)], now: now) == nil)
    }

    @Test func nothingMovingHasNoSummary() {
        #expect(TransferSummary([], now: now) == nil)
    }
}

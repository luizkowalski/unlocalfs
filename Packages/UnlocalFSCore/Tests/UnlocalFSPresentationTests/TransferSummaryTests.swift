import Testing
import UnlocalFSDomain
import UnlocalFSPresentation

@Suite struct TransferSummaryTests {
    @Test func uploadsLeadWhenFilesMoveBothWays() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "video.mov", size: 1000, state: .uploading, bytesTransferred: 600, bytesPerSecond: 200),
            FileActivity(path: "clip.mov", size: 500, state: .uploading, bytesTransferred: 200, bytesPerSecond: 100),
            FileActivity(path: "photo.jpg", size: 500, state: .queued, bytesTransferred: nil),
            FileActivity(path: "notes.txt", size: 300, state: .downloading, bytesTransferred: 100, bytesPerSecond: 5000)
        ]))

        #expect(summary.isUploading)
        #expect(summary.fileCount == 3)
        #expect(summary.bytesLeft == 1200)
        #expect(summary.bytesTotal == 2000)
        #expect(summary.bytesPerSecond == 300)
        #expect(summary.timeLeft == .seconds(4))
    }

    @Test func downloadsAloneAreCountedWithoutATotal() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "movie.mkv", size: 7_537_000_000, state: .downloading, bytesTransferred: 2_100_000, bytesPerSecond: 4096)
        ]))

        #expect(!summary.isUploading)
        #expect(summary.fileCount == 1)
        #expect(summary.bytesTotal == 0)
        #expect(summary.bytesPerSecond == 4096)
        #expect(summary.timeLeft == nil)
    }

    @Test func filesOfUnknownSizeCountWithoutBytes() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "stream.bin", size: -1, state: .uploading, bytesTransferred: 50, bytesPerSecond: 50)
        ]))

        #expect(summary.fileCount == 1)
        #expect(summary.bytesTotal == 0)
        #expect(summary.bytesPerSecond == 50)
        #expect(summary.timeLeft == nil)
    }

    @Test func queuedUploadsAloneHaveNoSpeedOrTimeLeft() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "photo.jpg", size: 500, state: .queued, bytesTransferred: nil)
        ]))

        #expect(summary.bytesPerSecond == nil)
        #expect(summary.timeLeft == nil)
    }

    @Test func movingFilesListBeforeRetriesAndQueuedUploads() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "a.txt", size: 1, state: .queued, bytesTransferred: nil),
            FileActivity(path: "b.txt", size: 1, state: .retrying, bytesTransferred: nil),
            FileActivity(path: "c.txt", size: 1, state: .downloading, bytesTransferred: 0),
            FileActivity(path: "d.txt", size: 1, state: .uploading, bytesTransferred: 0)
        ]))

        #expect(summary.files.map(\.state) == [.uploading, .downloading, .retrying, .queued])
    }

    @Test func filesInTheSameStateListByPath() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "file10.txt", size: 1, state: .queued, bytesTransferred: nil),
            FileActivity(path: "file2.txt", size: 1, state: .queued, bytesTransferred: nil)
        ]))

        #expect(summary.files.map(\.path) == ["file2.txt", "file10.txt"])
    }

    @Test func listStopsAtTenFiles() throws {
        let summary = try #require(TransferSummary((1...12).map {
            FileActivity(path: "file\($0).txt", size: 1, state: .queued, bytesTransferred: nil)
        }))

        #expect(summary.files.count == 10)
        #expect(summary.hiddenFileCount == 2)
    }

    @Test func nothingMovingHasNoSummary() {
        #expect(TransferSummary([]) == nil)
    }
}

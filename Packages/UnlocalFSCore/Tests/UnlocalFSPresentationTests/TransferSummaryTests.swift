import Testing
import UnlocalFSDomain
import UnlocalFSPresentation

@Suite struct TransferSummaryTests {
    @Test func uploadsLeadWhenFilesMoveBothWays() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "video.mov", size: 1000, state: .uploading, bytesTransferred: 600),
            FileActivity(path: "photo.jpg", size: 500, state: .queued, bytesTransferred: nil),
            FileActivity(path: "notes.txt", size: 300, state: .downloading, bytesTransferred: 100)
        ]))

        #expect(summary.isUploading)
        #expect(summary.fileCount == 2)
        #expect(summary.bytesLeft == 900)
        #expect(summary.bytesTotal == 1500)
    }

    @Test func downloadsAloneAreSummarized() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "notes.txt", size: 300, state: .downloading, bytesTransferred: 100)
        ]))

        #expect(!summary.isUploading)
        #expect(summary.fileCount == 1)
        #expect(summary.bytesLeft == 200)
    }

    @Test func filesOfUnknownSizeCountWithoutBytes() throws {
        let summary = try #require(TransferSummary([
            FileActivity(path: "stream.bin", size: -1, state: .uploading, bytesTransferred: 50)
        ]))

        #expect(summary.fileCount == 1)
        #expect(summary.bytesTotal == 0)
    }

    @Test func nothingMovingHasNoSummary() {
        #expect(TransferSummary([]) == nil)
    }
}

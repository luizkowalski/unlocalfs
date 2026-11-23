import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSTestSupport

struct VersionListingTests {
    private func version(_ path: String, at seconds: TimeInterval) -> FileVersion {
        FileVersion(path: path, size: 3, savedAt: Date(timeIntervalSince1970: seconds))
    }

    @Test func historyListsTheCurrentFileFirstThenOldVersionsNewestFirst() {
        let listing = VersionListing([
            version("sub/report-v2026-10-30-090000-000.txt", at: 1),
            version("sub/report.txt", at: 3),
            version("sub/report-v2026-11-02-140301-123.txt", at: 2),
            version("sub/other.txt", at: 4),
        ])
        let history = listing.history(of: "sub/report.txt")
        #expect(history.map(\.path) == ["sub/report.txt", "sub/report-v2026-11-02-140301-123.txt", "sub/report-v2026-10-30-090000-000.txt"])
        #expect(history.map(\.isCurrent) == [true, false, false])
        #expect(history.allSatisfy { $0.name == "report.txt" })
    }

    @Test(arguments: [
        ("Makefile-v2026-11-02-140301-000", "Makefile", false),
        ("archive.tar-v2026-11-02-140301-000.gz", "archive.tar.gz", false),
        ("notes-v2-final.txt", "notes-v2-final.txt", true),
    ])
    func versionNamesMapToTheirFile(name: String, file: String, isCurrent: Bool) {
        let version = version(name, at: 1)
        #expect(version.filePath == file)
        #expect(version.isCurrent == isCurrent)
    }

    @Test func deletedFilesAreFilesWithOnlyOldVersionsNewestDeletionFirst() {
        let listing = VersionListing([
            version("photo-v2026-11-01-100000-000.jpg", at: 1),
            version("photo-v2026-11-02-100000-000.jpg", at: 5),
            version("report-v2026-11-01-100000-000.txt", at: 2),
            version("report.txt", at: 3),
            version("notes-v2026-11-03-100000-000.md", at: 4),
        ])
        #expect(listing.deletedFiles.map(\.path) == ["photo-v2026-11-02-100000-000.jpg", "notes-v2026-11-03-100000-000.md"])
    }

    @Test func versionsShowOnlyForS3Drives() {
        #expect(Connection.s3().versionsRefusal == nil)
        #expect(Connection.s3 { $0.encrypted = true }.versionsRefusal == nil)
        #expect(Connection.sftp().versionsRefusal != nil)
        #expect(Connection.gcs().versionsRefusal != nil)
    }
}

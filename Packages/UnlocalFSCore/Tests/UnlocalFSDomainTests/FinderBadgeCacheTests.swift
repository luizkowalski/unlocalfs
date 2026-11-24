import Foundation
import Testing
@testable import UnlocalFSDomain

struct FinderBadgeCacheTests {
    private let drive = URL(filePath: "/Users/me/UnlocalFS/Photos", directoryHint: .isDirectory)
    private let start = Date(timeIntervalSinceReferenceDate: 1000)

    private func snapshot(_ uploads: [String: UploadState] = [:], version: Int = 1, checkedAt: Date) -> FinderSyncReply {
        .snapshot(FinderSnapshot(drives: [.init(mount: drive, uploads: uploads)]), version: version, checkedAt: [drive: checkedAt])
    }

    @Test func aNewFileShowsCheckingUntilAStatusCheckThatStartedAfterFinderAskedForIt() {
        var cache = FinderBadgeCache()
        let file = drive.appending(path: "new.pdf")
        let outside = URL(filePath: "/Users/me/UnlocalFS/notes.txt")
        _ = cache.receive(snapshot(["new.pdf": .failed], checkedAt: start - 1))

        let firstTime = cache.see(file, at: start)
        let secondTime = cache.see(file, at: start + 1)
        _ = cache.see(outside, at: start)
        let waiting = (file: cache.badge(for: file), outside: cache.badge(for: outside))
        let olderCheck = cache.receive(.unchanged(checkedAt: [drive: start - 1]))
        let newerCheck = cache.receive(.unchanged(checkedAt: [drive: start + 1]))

        #expect(firstTime && !secondTime)
        #expect(waiting.file == .checking && waiting.outside == nil)
        #expect(olderCheck == FinderUpdate(badges: [outside: nil], watchedFolders: nil, pullAgainAfter: 0.5))
        #expect(newerCheck == FinderUpdate(badges: [file: .failed], watchedFolders: nil, pullAgainAfter: nil))
    }

    @Test func aSnapshotBadgesKnownFilesAndWatchesItsDrivesOnlyWhenTheyChange() {
        var cache = FinderBadgeCache()
        let old = drive.appending(path: "old.pdf")
        let new = drive.appending(path: "new.pdf")
        _ = cache.see(old, at: start)
        _ = cache.see(new, at: start + 10)

        let first = cache.receive(snapshot(checkedAt: start + 5))
        let later = cache.receive(snapshot(["old.pdf": .pending], version: 2, checkedAt: start + 20))

        #expect(first == FinderUpdate(badges: [old: .uploaded], watchedFolders: [drive, drive.deletingLastPathComponent()], pullAgainAfter: 0.5))
        #expect(later == FinderUpdate(badges: [old: .uploading, new: .uploaded], watchedFolders: nil, pullAgainAfter: nil))
        #expect(cache.version == 2)
    }

    @Test func eachNewFileWaitsOnlyForACheckOfItsOwnDrive() {
        var cache = FinderBadgeCache()
        let busyDrive = URL(filePath: "/Users/me/UnlocalFS/Work", directoryHint: .isDirectory)
        let photo = drive.appending(path: "new.jpg")
        let report = busyDrive.appending(path: "new.pdf")
        for url in [photo, report] {
            _ = cache.see(url, at: start)
        }

        let photoChecked = cache.receive(.unchanged(checkedAt: [drive: start + 1, busyDrive: start - 1]))
        let bothChecked = cache.receive(.unchanged(checkedAt: [drive: start + 1, busyDrive: start + 1]))

        #expect(Set(photoChecked.badges.keys) == [photo] && photoChecked.pullAgainAfter == 0.5)
        #expect(Set(bothChecked.badges.keys) == [report] && bothChecked.pullAgainAfter == nil)
    }

    @Test func aFolderFinderStopsShowingDropsOnlyItsFiles() {
        var cache = FinderBadgeCache()
        let kept = drive.appending(path: "a/kept.pdf")
        let dropped = drive.appending(path: "b/dropped.pdf")
        _ = cache.see(kept, at: start)
        _ = cache.see(dropped, at: start)

        cache.forget(folder: drive.appending(path: "b", directoryHint: .isDirectory))

        #expect(Set(cache.receive(.unchanged(checkedAt: [drive: start + 1])).badges.keys) == [kept])
    }

    @Test func aTimeoutKeepsTheBadgesAndAFailedReplyClearsThemAndStartsOver() {
        var cache = FinderBadgeCache()
        let file = drive.appending(path: "a.pdf")
        _ = cache.see(file, at: start)
        _ = cache.receive(snapshot(checkedAt: start + 1))

        let timeout = cache.receive(nil)
        let failed = cache.receive(.failed)

        #expect(timeout == FinderUpdate(badges: [:], watchedFolders: nil, pullAgainAfter: 3))
        #expect(failed == FinderUpdate(badges: [file: nil], watchedFolders: [], pullAgainAfter: nil))
        #expect(cache.version == nil)
        let seenAgain = cache.see(file, at: start + 2)
        let watchesAgain = cache.receive(snapshot(checkedAt: start + 3)).watchedFolders
        #expect(seenAgain && watchesAgain != nil)
    }
}

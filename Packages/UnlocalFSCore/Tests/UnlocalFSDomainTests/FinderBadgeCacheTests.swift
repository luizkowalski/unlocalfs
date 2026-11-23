import Foundation
import Testing
import UnlocalFSDomain

struct FinderBadgeCacheTests {
    private let drive = URL(filePath: "/Users/me/UnlocalFS/Photos", directoryHint: .isDirectory)
    private let start = Date(timeIntervalSinceReferenceDate: 1000)

    private func badges(_ uploads: [String: UploadState]) -> FinderBadges {
        FinderBadges(FinderSnapshot(drives: [.init(mount: drive, uploads: uploads)]))
    }

    @Test func aNewFileWaitsForAStatusCheckThatStartedAfterFinderAskedForIt() {
        var cache = FinderBadgeCache()
        let file = drive.appending(path: "new.pdf")

        let firstTime = cache.see(file, at: start)
        let secondTime = cache.see(file, at: start + 1)
        let olderCheck = cache.confirm(checkedAt: start - 1)
        let stillWaiting = cache.isWaiting
        let newerCheck = cache.confirm(checkedAt: start + 1)

        #expect(firstTime && !secondTime)
        #expect(olderCheck.isEmpty && stillWaiting)
        #expect(newerCheck == [file])
        #expect(!cache.isWaiting)
    }

    @Test func aSnapshotBadgesKnownFilesButNotFilesSeenAfterItsCheck() {
        var cache = FinderBadgeCache()
        let old = drive.appending(path: "old.pdf")
        let new = drive.appending(path: "new.pdf")
        _ = cache.see(old, at: start)
        _ = cache.see(new, at: start + 10)

        let result = cache.apply(badges([:]), version: 1, watching: [drive], checkedAt: start + 5)

        #expect(result.foldersChanged)
        #expect(result.ready == [old])
        #expect(cache.isWaiting)
        let later = cache.apply(badges([:]), version: 2, watching: [drive], checkedAt: start + 20)
        #expect(!later.foldersChanged && later.ready == [old, new])
        #expect(cache.version == 2)
        #expect(!cache.isWaiting)
    }

    @Test func aFolderFinderStopsShowingDropsOnlyItsFiles() {
        var cache = FinderBadgeCache()
        let kept = drive.appending(path: "a/kept.pdf")
        let dropped = drive.appending(path: "b/dropped.pdf")
        _ = cache.see(kept, at: start)
        _ = cache.see(dropped, at: start)

        cache.forget(folder: drive.appending(path: "b", directoryHint: .isDirectory))

        #expect(cache.confirm(checkedAt: start + 1) == [kept])
    }

    @Test func resetReturnsWhatToClearAndStartsOver() {
        var cache = FinderBadgeCache()
        let file = drive.appending(path: "a.pdf")
        _ = cache.see(file, at: start)
        _ = cache.apply(badges([:]), version: 1, watching: [drive], checkedAt: start + 1)

        let cleared = cache.reset()

        #expect(cleared.known == [file] && cleared.watched == [drive])
        #expect(cache.version == nil)
        let seenAgain = cache.see(file, at: start + 2)
        let watchesAgain = cache.apply(badges([:]), version: 2, watching: [drive], checkedAt: start + 3).foldersChanged
        #expect(seenAgain && watchesAgain)
    }
}

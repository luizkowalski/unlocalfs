import Foundation
import Testing
import UnlocalFSDomain

struct FinderBadgeTests {
    private static let mounts = URL(filePath: "/Users/me/UnlocalFS", directoryHint: .isDirectory)
    private static let photos = mounts.appending(path: "Photos", directoryHint: .isDirectory)
    private static let photos2 = mounts.appending(path: "Photos 2", directoryHint: .isDirectory)

    private static let badges = FinderBadges(FinderSnapshot(drives: [
        .init(mount: photos, uploads: ["a/b/report.pdf": .uploading, "a/c/photo.jpg": .failed, "a/bc/x": .waiting, "photos2/x.jpg": .waiting]),
        .init(mount: photos2, uploads: [:]),
    ]))

    @Test(arguments: [
        ("", FinderBadge.failed),
        ("a", .failed),
        ("a/b", .uploading),
        ("a/b/report.pdf", .uploading),
        ("a/c", .failed),
        ("a/c/photo.jpg", .failed),
        ("a/c/other.jpg", .uploaded),
        ("a/bc", .uploading),
        ("z.txt", .uploaded),
        ("photos", .uploaded),
        ("photos2", .uploading),
    ])
    func filesAndFoldersShowTheWorstUploadUnderThem(path: String, expected: FinderBadge) {
        #expect(Self.badges.badge(for: Self.photos.appending(path: path)) == expected)
    }

    @Test func aFolderNeverTakesTheStateOfASiblingWithTheSamePrefix() {
        #expect(Self.badges.badge(for: Self.photos.appending(path: "a/b", directoryHint: .isDirectory)) == .uploading)
        let onlySibling = FinderBadges(FinderSnapshot(drives: [.init(mount: Self.photos, uploads: ["a/bc/x": .failed])]))
        #expect(onlySibling.badge(for: Self.photos.appending(path: "a/b")) == .uploaded)
    }

    @Test func anEmptyQueueShowsEverythingAsUploaded() {
        let badges = FinderBadges(FinderSnapshot(drives: [.init(mount: Self.photos, uploads: [:])]))
        #expect(badges.badge(for: Self.photos) == .uploaded)
        #expect(badges.badge(for: Self.photos.appending(path: "any/file.txt")) == .uploaded)
    }

    @Test func aDecomposedNameFromFinderMatchesAPrecomposedQueueName() {
        let badges = FinderBadges(FinderSnapshot(drives: [.init(mount: Self.photos, uploads: ["Fotos/caf\u{E9}.jpg": .failed])]))
        #expect(badges.badge(for: Self.photos.appending(path: "Fotos/cafe\u{301}.jpg")) == .failed)
    }

    @Test func eachURLBelongsOnlyToTheDriveWhoseWholeMountPathItStartsWith() {
        let badges = FinderBadges(FinderSnapshot(drives: [
            .init(mount: Self.photos, uploads: [:]),
            .init(mount: Self.photos2, uploads: ["x.jpg": .failed]),
        ]))
        #expect(badges.badge(for: Self.photos2.appending(path: "x.jpg")) == .failed)
        #expect(badges.badge(for: Self.photos2) == .failed)
        #expect(badges.badge(for: Self.photos.appending(path: "x.jpg")) == .uploaded)
        #expect(badges.badge(for: Self.photos) == .uploaded)
        #expect(badges.badge(for: Self.mounts.appending(path: "Old Drive")) == nil)
        #expect(badges.badge(for: URL(filePath: "/Users/me/Documents/x.jpg")) == nil)
    }

    @Test func finderWatchesEachMountAndTheFolderThatHoldsThem() {
        let snapshot = FinderSnapshot(drives: [.init(mount: Self.photos, uploads: [:]), .init(mount: Self.photos2, uploads: [:])])
        #expect(snapshot.watchedFolders.map(\.path).sorted() == [Self.mounts.path, Self.photos.path, Self.photos2.path])
        #expect(FinderSnapshot(drives: []).watchedFolders.isEmpty)
    }
}

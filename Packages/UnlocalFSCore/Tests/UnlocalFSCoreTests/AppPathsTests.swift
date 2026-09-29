import Foundation
import Testing
import UnlocalFSCore

@Suite struct AppPathsTests {
    @Test func removingCacheDeletesAllCachedFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = paths(root: root)
        let connection = fixture()
        let cache = paths.cache(connection)
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        try Data("cached".utf8).write(to: cache.appendingPathComponent("file"))

        paths.removeCache(connection)

        #expect(!FileManager.default.fileExists(atPath: cache.path))
    }

    @Test func removingMissingCacheDoesNotThrow() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let paths = paths(root: root)

        paths.removeCache(fixture())
    }
}

private func paths(root: URL) -> AppPaths {
    AppPaths(
        config: root.appendingPathComponent("config.json"),
        support: root.appendingPathComponent("support"),
        mounts: root.appendingPathComponent("mounts"),
        logs: root.appendingPathComponent("logs")
    )
}

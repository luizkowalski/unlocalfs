import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSTestSupport

struct AppPathsTests {
    @Test(arguments: [
        ("mounts/My files/report.pdf", "My files/report.pdf"),
        ("mounts/My files/trips/2026/plan é.txt", "My files/trips/2026/plan é.txt"),
        ("mounts/Photos 2/a.jpg", "Photos 2/a.jpg"),
        ("mounts/Photos/a.jpg", "Photos/a.jpg"),
        ("mounts/My files", nil),
        ("mounts/Unknown/a.txt", nil),
        ("elsewhere/a.txt", nil),
    ] as [(String, String?)])
    func filesInsideADriveMapToTheirDrivePath(file: String, expected: String?) {
        let root = URL(filePath: "/tmp/unlocalfs-paths")
        let connections = ["My files", "Photos", "Photos 2"].map { Connection.s3(name: $0) }

        let location = paths(root: root).drive(containing: root.appending(path: file), among: connections)

        #expect(location.map { "\($0.connection.name)/\($0.path)" } == expected)
    }
}

private func paths(root: URL) -> AppPaths {
    AppPaths(
        config: root.appendingPathComponent("config.json"),
        support: root.appendingPathComponent("support"),
        mounts: root.appendingPathComponent("mounts"),
        logs: root.appendingPathComponent("logs"),
    )
}

import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSTestSupport

struct RemoteFileTests {
    @Test(arguments: [
        ("drives/My files/report.pdf", "My files/report.pdf"),
        ("drives/My files/trips/2026/plan é.txt", "My files/trips/2026/plan é.txt"),
        ("drives/Photos 2/a.jpg", "Photos 2/a.jpg"),
        ("drives/Photos/a.jpg", "Photos/a.jpg"),
        ("drives/My files", nil),
        ("drives/Unknown/a.txt", nil),
        ("elsewhere/a.txt", nil),
    ] as [(String, String?)])
    func filesInsideADriveMapToTheirDrivePath(file: String, expected: String?) throws {
        let drives = try StubbedDrives("paths")
        defer { drives.remove() }
        let connections = ["My files", "Photos", "Photos 2"].map { Connection.s3(name: $0) }

        let location = drives.service.remoteFile(drives.root.appending(path: file), among: connections)

        #expect(location.map { "\($0.connection.name)/\($0.path)" } == expected)
    }
}

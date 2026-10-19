import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation

@Suite struct SpeedSampleTests {
    let start = Date(timeIntervalSinceReferenceDate: 1_000)

    func sample(_ offset: TimeInterval, upload: Double = 0, download: Double = 0) -> SpeedSample {
        var status = MountStatus()
        status.uploadSpeed = upload
        status.downloadSpeed = download
        return SpeedSample(status, at: start + offset)
    }

    @Test func hoverPicksTheClosestSample() {
        let speeds = [sample(0, upload: 1), sample(1, upload: 2), sample(2, upload: 3)]

        #expect(speeds.nearest(to: start + 1.4)?.upload == 2)
        #expect(speeds.nearest(to: start + 1.6)?.upload == 3)
        #expect(speeds.nearest(to: start + 10)?.upload == 3)
    }

    @Test func axisLeavesRoomAboveTheFastestSpeedInEitherDirection() {
        let speeds = [sample(0, upload: 300_000, download: 100_000), sample(1, upload: 200_000, download: 500_000)]

        #expect(speeds.fastestUpload == 300_000)
        #expect(speeds.fastestDownload == 500_000)
        #expect(speeds.axisLimit == 500_000 * 1.1)
    }

    @Test func axisShowsAtLeastOneHundredKilobytesPerSecond() {
        #expect([sample(0, upload: 10)].axisLimit == 100_000 * 1.1)
        #expect([SpeedSample]().axisLimit == 100_000 * 1.1)
    }
}

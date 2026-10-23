import Foundation
import Observation
import Synchronization
import Testing
@testable import UnlocalFSDomain
import UnlocalFSTestSupport
import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation

@MainActor @Suite final class SpeedRecordingTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func statusChecksKeepSpeedHistoryForRunningDrivesOnly() async throws {
        let stopped = Connection.s3()
        let running = Connection.s3(name: "Running")
        try ConnectionStore(url: fixture.paths.config).save(stopped)
        try fixture.serve(running)
        try fixture.queue(#"{"name":"a.mov","id":1,"size":1000,"expiry":4,"tries":0,"delay":5,"uploading":false}"#)
        try Data("""
        {\(rcloneCounters),"transferring":[
            {"name":"a.mov","size":1000,"bytes":100,"speedAvg":3000,"srcFs":"/cache","dstFs":":s3:bucket"},
            {"name":"b.mov","size":1000,"bytes":100,"speedAvg":2000,"srcFs":"/cache","dstFs":":s3:bucket"},
            {"name":"c.mov","size":1000,"bytes":100,"speedAvg":500,"srcFs":":s3:bucket"}
        ]}
        """.utf8).write(to: fixture.root.appending(path: "stats.json"))
        let app = fixture.app()

        await app.refresh()

        #expect(app.speeds[running.id]?.map { [$0.upload, $0.download] } == [[2000, 500]])
        #expect(app.speeds[stopped.id] == nil)
    }

    @Test func speedHistoryKeepsTheNewestSampleOfEachSecondForOneMinute() {
        let app = fixture.app()
        let drive = UUID()
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        func record(_ offset: TimeInterval, _ speed: Double) {
            var status = MountStatus()
            status.uploadSpeed = speed
            app.recordSpeed(SpeedSample(status, at: start + offset), for: drive)
        }

        record(0, 1)
        record(0.4, 2)
        record(0.9, 3)
        record(1.1, 4)
        record(2, 5)
        #expect(app.speeds[drive]?.map(\.upload) == [3, 4, 5])

        record(61.5, 6)
        #expect(app.speeds[drive]?.map(\.upload) == [5, 6])

        record(10.5, 7)
        #expect(app.speeds[drive]?.map(\.upload) == [5, 7])

        record(10.2, 8)
        #expect(app.speeds[drive]?.map(\.upload) == [5, 8])
    }

    @Test func unchangedSpeedWithinTheSameSecondDoesNotNotifyObservers() {
        let app = fixture.app()
        let drive = UUID()
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        var status = MountStatus()
        status.uploadSpeed = 5
        app.recordSpeed(SpeedSample(status, at: start), for: drive)
        let changed = Mutex(false)
        withObservationTracking { _ = app.speeds } onChange: { changed.withLock { $0 = true } }

        app.recordSpeed(SpeedSample(status, at: start + 0.5), for: drive)

        #expect(!changed.withLock { $0 })
    }
}

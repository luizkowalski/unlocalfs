import Testing
@testable import UnlocalFSDomain

struct DriveConditionTests {
    @Test func aDriveWithoutAReadingIsChecking() {
        #expect(condition(nil) == .checking)
    }

    @Test func aRunningOperationOutranksEveryReadingAndError() {
        let unreachable = reading(mounted: true, running: true, failed: 2, controlError: "Unavailable")

        #expect(condition(unreachable, busy: true, error: "Failed", online: false) == .working)
    }

    @Test func anUnreachableServiceOutranksAReportedError() {
        #expect(condition(reading(mounted: true, controlError: "Unavailable"), error: "Failed") == .needsReconnect)
    }

    @Test func aReportedErrorOutranksTheReading() {
        #expect(condition(reading(mounted: true, running: true), error: "Failed") == .needsAttention)
    }

    @Test func anActiveDriveWithoutANetworkIsOffline() {
        #expect(condition(reading(mounted: true), online: false) == .offline)
        #expect(condition(reading(running: true), online: false) == .offline)
        #expect(condition(reading(), online: false) == .disconnected)
    }

    @Test func failedUploadsOutrankPendingOnes() {
        #expect(condition(reading(mounted: true, pending: 3, failed: 1)) == .uploadFailed)
    }

    @Test func pendingUploadsOutrankTheMount() {
        #expect(condition(reading(mounted: true, pending: 2)) == .uploading(count: 2))
    }

    @Test func aMountedDriveIsConnected() {
        #expect(condition(reading(mounted: true, running: true)) == .connected)
    }

    @Test func aRunningServiceWithoutAMountIsEjected() {
        #expect(condition(reading(running: true)) == .ejected)
    }

    @Test func aStoppedDriveIsDisconnected() {
        #expect(condition(reading()) == .disconnected)
    }

    private func condition(
        _ status: MountStatus?, busy: Bool = false, error: String? = nil, online: Bool = true,
    ) -> DriveCondition {
        DriveCondition(status, busy: busy, error: error, networkAvailable: online)
    }

    private func reading(
        mounted: Bool = false, running: Bool = false, pending: Int = 0, failed: Int = 0, controlError: String? = nil,
    ) -> MountStatus {
        var status = MountStatus()
        status.isMounted = mounted
        status.isRunning = running
        status.pendingUploads = pending
        status.failedUploads = failed
        status.controlError = controlError
        return status
    }
}

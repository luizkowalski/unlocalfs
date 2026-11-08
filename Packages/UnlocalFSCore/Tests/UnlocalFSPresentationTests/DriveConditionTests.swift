import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation

struct DriveConditionTests {
    @Test func aDriveWithoutAReadingIsChecking() {
        #expect(condition(nil) == .checking)
    }

    @Test func aRunningOperationOutranksEveryReadingAndError() {
        let unreachable = reading(mounted: true, running: true, failed: 2, controlError: "Unavailable")

        #expect(condition(unreachable, busy: true, hasError: true, offline: true) == .working)
    }

    @Test func anUnreachableServiceOutranksAReportedError() {
        #expect(condition(reading(mounted: true, controlError: "Unavailable"), hasError: true) == .needsReconnect)
    }

    @Test func aReportedErrorOutranksTheReadingAndTheNetwork() {
        #expect(condition(reading(mounted: true, running: true), hasError: true) == .needsAttention)
        #expect(condition(reading(mounted: true), hasError: true, offline: true) == .needsAttention)
    }

    @Test func aReportedErrorShowsBeforeTheFirstReading() {
        #expect(condition(nil, hasError: true) == .needsAttention)
    }

    @Test func aMissingNetworkOutranksUploads() {
        #expect(condition(reading(mounted: true, pending: 1, failed: 1), offline: true) == .offline)
    }

    @Test func failedUploadsOutrankPendingOnes() {
        #expect(condition(reading(mounted: true, pending: 3, failed: 1)) == .uploadFailed)
    }

    @Test func pendingUploadsOutrankTheMount() {
        #expect(condition(reading(mounted: true, pending: 2)) == .uploading(count: 2, isMounted: true))
    }

    @Test func aDotShowsAConnectedDriveWhileItUploads() {
        #expect(condition(reading(mounted: true, pending: 2)).indicator == .connected)
        #expect(condition(reading(running: true, pending: 2)).indicator == .idle)
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
        _ status: MountStatus?, busy: Bool = false, hasError: Bool = false, offline: Bool = false,
    ) -> DriveCondition {
        DriveCondition(status, busy: busy, hasError: hasError, offline: offline)
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

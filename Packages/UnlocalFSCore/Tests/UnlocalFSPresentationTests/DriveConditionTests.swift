import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation

struct DriveConditionTests {
    @Test func whichStateWinsWhenSeveralApply() {
        let unreachable = reading(mounted: true, running: true, failed: 2, controlError: "Unavailable")
        let mounted = reading(mounted: true, running: true)
        let uploading = reading(mounted: true, running: true, pending: 2)

        #expect(condition(unreachable, busy: true, hasError: true, offline: true) == .working)
        #expect(condition(unreachable, hasError: true) == .needsReconnect)
        #expect(condition(mounted, hasError: true) == .needsAttention)
        #expect(condition(mounted, hasError: true, offline: true) == .needsAttention)
        #expect(condition(uploading) == .uploading(count: 2, isMounted: true))
        #expect(condition(uploading).indicator == .connected)
        #expect(condition(mounted) == .connected)
        #expect(condition(mounted).indicator == .connected)
    }

    @Test func revokedGoogleSignInWinsOverTheUploadFailure() {
        var revoked = reading(mounted: true, running: true, failed: 1)
        #expect(condition(revoked) == .uploadFailed)
        revoked.needsSignIn = true
        #expect(condition(revoked) == .needsSignIn)
        #expect(condition(revoked).indicator == .attention)
        #expect(condition(revoked, busy: true) == .working)
    }

    private func condition(
        _ status: MountStatus, busy: Bool = false, hasError: Bool = false, offline: Bool = false,
    ) -> DriveCondition {
        DriveCondition(status, busy: busy, hasError: hasError, offline: offline)
    }

    private func reading(
        mounted: Bool, running: Bool, pending: Int = 0, failed: Int = 0, controlError: String? = nil,
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

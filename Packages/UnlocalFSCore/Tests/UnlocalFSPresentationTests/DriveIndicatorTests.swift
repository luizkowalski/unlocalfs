import Testing
import UnlocalFSDomain
@testable import UnlocalFSPresentation

struct DriveIndicatorTests {
    @Test func everyConditionChoosesADot() {
        #expect(indicator(.checking, mounted: false) == .idle)
        #expect(indicator(.working, mounted: true) == .working)
        #expect(indicator(.needsReconnect, mounted: true) == .attention)
        #expect(indicator(.needsAttention, mounted: true) == .attention)
        #expect(indicator(.offline, mounted: true) == .attention)
        #expect(indicator(.uploadFailed, mounted: true) == .attention)
        #expect(indicator(.uploading(count: 2), mounted: true) == .connected)
        #expect(indicator(.uploading(count: 2), mounted: false) == .idle)
        #expect(indicator(.connected, mounted: true) == .connected)
        #expect(indicator(.ejected, mounted: false) == .idle)
        #expect(indicator(.disconnected, mounted: false) == .idle)
    }

    private func indicator(_ condition: DriveCondition, mounted: Bool) -> AppViewModel.Indicator {
        AppViewModel.Indicator(condition, isMounted: mounted)
    }
}

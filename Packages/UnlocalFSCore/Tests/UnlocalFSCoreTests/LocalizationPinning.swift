import Foundation
@testable import UnlocalFSDomain
@testable import UnlocalFSInfrastructure

/// Pins every localized module's lookup to its `en.lproj` sub-bundle so string
/// assertions keep raw English literals on any host locale.
func pinEnglish() {
    if let english = UnlocalFSDomain.L10n.englishBundle as Bundle? { UnlocalFSDomain.L10n.bundle = english }
    if let english = UnlocalFSInfrastructure.L10n.englishBundle as Bundle? { UnlocalFSInfrastructure.L10n.bundle = english }
}

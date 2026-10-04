import Foundation
@testable import UnlocalFSDomain
@testable import UnlocalFSPresentation

/// Pins each localized module's lookup to its `en.lproj` sub-bundle so string
/// assertions keep raw English literals on any host locale.
func pinEnglish() {
    UnlocalFSDomain.L10n.bundle = UnlocalFSDomain.L10n.englishBundle
    UnlocalFSPresentation.L10n.bundle = UnlocalFSPresentation.L10n.englishBundle
}

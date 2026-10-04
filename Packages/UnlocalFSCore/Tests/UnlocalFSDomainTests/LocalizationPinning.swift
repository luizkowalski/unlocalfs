import Foundation
@testable import UnlocalFSDomain

/// Pins the Domain localization lookup to its `en.lproj` sub-bundle so string
/// assertions keep raw English literals on any host locale.
func pinEnglish() {
    L10n.bundle = L10n.englishBundle
}

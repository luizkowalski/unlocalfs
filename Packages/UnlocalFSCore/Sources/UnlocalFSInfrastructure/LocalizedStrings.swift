import Foundation

/// English text is the localization key; the en table is empty, so English
/// output is the key itself. Test suites pin `bundle` to the module's
/// `en.lproj` sub-bundle so string assertions pass on any host locale.
enum L10n {
    nonisolated(unsafe) static var bundle: Bundle = .module

    static func text(_ key: String.LocalizationValue) -> String {
        String(localized: key, table: "Localizable", bundle: bundle)
    }
}

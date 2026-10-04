import Foundation

public enum AppLanguage: String, Sendable {
    case system
    case english = "en"
    case portuguese = "pt-BR"

    /// Reads the app's own plist via CFPreferencesCopyValue (no search-list
    /// fallback), so a System selection stays distinct from an explicit
    /// language that happens to match the system.
    static func stored(bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "") -> AppLanguage {
        let value = CFPreferencesCopyValue(
            "AppleLanguages" as CFString,
            bundleIdentifier as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        ) as? [String]
        return value?.first.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }
}

import ClipCore
import Foundation

/// Cài đặt lưu trong UserDefaults (DESIGN §4).
@MainActor
enum Preferences {
    private static let defaults = UserDefaults.standard

    static func registerDefaults() {
        defaults.register(defaults: [
            Key.historyLimit: 500,
            Key.autoPaste: true,
            Key.ignoreConcealed: true,
            Key.maxImageMB: 20,
            Key.excludedBundleIDs: PrivacyFilter.defaultExcludedBundleIDs,
        ])
    }

    enum Key {
        static let historyLimit = "historyLimit"
        static let autoPaste = "autoPaste"
        static let launchAtLogin = "launchAtLogin"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let ignoreConcealed = "ignoreConcealed"
        static let pausedUntil = "pausedUntil"
        static let maxImageMB = "maxImageMB"
    }

    static var historyLimit: Int {
        get { defaults.integer(forKey: Key.historyLimit) }
        set { defaults.set(newValue, forKey: Key.historyLimit) }
    }

    static var maxImageMB: Int {
        get { defaults.integer(forKey: Key.maxImageMB) }
        set { defaults.set(newValue, forKey: Key.maxImageMB) }
    }

    static var autoPaste: Bool {
        get { defaults.bool(forKey: Key.autoPaste) }
        set { defaults.set(newValue, forKey: Key.autoPaste) }
    }

    static var ignoreConcealed: Bool {
        get { defaults.bool(forKey: Key.ignoreConcealed) }
        set { defaults.set(newValue, forKey: Key.ignoreConcealed) }
    }

    static var excludedBundleIDs: [String] {
        get { defaults.stringArray(forKey: Key.excludedBundleIDs) ?? [] }
        set { defaults.set(newValue, forKey: Key.excludedBundleIDs) }
    }

    static var pausedUntil: Date? {
        get { defaults.object(forKey: Key.pausedUntil) as? Date }
        set { defaults.set(newValue, forKey: Key.pausedUntil) }
    }
}

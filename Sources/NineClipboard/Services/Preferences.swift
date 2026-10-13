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

    static var autoPaste: Bool {
        get { defaults.bool(forKey: Key.autoPaste) }
        set { defaults.set(newValue, forKey: Key.autoPaste) }
    }
}

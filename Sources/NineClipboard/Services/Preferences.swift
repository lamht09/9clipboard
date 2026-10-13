import Foundation

/// Cài đặt lưu trong UserDefaults (DESIGN §4).
@MainActor
enum Preferences {
    private static let defaults = UserDefaults.standard

    static func registerDefaults() {
        defaults.register(defaults: [
            Key.historyLimit: 500,
            Key.autoPaste: true,
            Key.detectPasswords: true,
            Key.passwordLifetimeMinutes: 15,
            Key.maxImageMB: 20,
        ])
    }

    enum Key {
        static let historyLimit = "historyLimit"
        static let autoPaste = "autoPaste"
        static let launchAtLogin = "launchAtLogin"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let detectPasswords = "detectPasswords"
        static let passwordLifetimeMinutes = "passwordLifetimeMinutes"
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

    /// Nhận diện mật khẩu (type Concealed, app quản lý mật khẩu) để tự xoá sau `passwordLifetimeMinutes`.
    static var detectPasswords: Bool {
        get { defaults.bool(forKey: Key.detectPasswords) }
        set { defaults.set(newValue, forKey: Key.detectPasswords) }
    }

    /// Mật khẩu tự xoá sau bao nhiêu phút nếu người dùng không giữ lại. Sửa được ở Settings (M8).
    static var passwordLifetimeMinutes: Int {
        get { max(1, defaults.integer(forKey: Key.passwordLifetimeMinutes)) }
        set { defaults.set(newValue, forKey: Key.passwordLifetimeMinutes) }
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

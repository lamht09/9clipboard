import Foundation

/// Cài đặt lưu trong UserDefaults.
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
            Key.autoCheckUpdates: true,
            Key.autoInstallUpdates: false,
            Key.includeBetaUpdates: false,
        ])
    }

    enum Key {
        static let historyLimit = "historyLimit"
        static let autoPaste = "autoPaste"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let detectPasswords = "detectPasswords"
        static let passwordLifetimeMinutes = "passwordLifetimeMinutes"
        static let pausedUntil = "pausedUntil"
        static let maxImageMB = "maxImageMB"
        static let hotkey = "hotkey"
        static let autoCheckUpdates = "autoCheckUpdates"
        static let autoInstallUpdates = "autoInstallUpdates"
        static let lastUpdateCheck = "lastUpdateCheck"
        static let includeBetaUpdates = "includeBetaUpdates"
    }

    /// Phím tắt mở panel (mặc định ⌥V).
    static var hotkey: HotkeyManager.Shortcut {
        get {
            defaults.data(forKey: Key.hotkey)
                .flatMap { try? JSONDecoder().decode(HotkeyManager.Shortcut.self, from: $0) } ?? .default
        }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: Key.hotkey) }
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

    /// Mật khẩu tự xoá sau bao nhiêu phút nếu người dùng không giữ lại. Sửa ở Settings › Riêng tư.
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

    /// Tự hỏi GitHub phiên bản mới nhất (mỗi ngày và khi mở Settings). Tắt thì chỉ kiểm tra khi bấm nút.
    static var autoCheckUpdates: Bool {
        get { defaults.bool(forKey: Key.autoCheckUpdates) }
        set { defaults.set(newValue, forKey: Key.autoCheckUpdates) }
    }

    /// Có bản mới thì tự tải, cài và khởi động lại (khi panel đang đóng). Cần bật `autoCheckUpdates`.
    static var autoInstallUpdates: Bool {
        get { defaults.bool(forKey: Key.autoInstallUpdates) }
        set { defaults.set(newValue, forKey: Key.autoInstallUpdates) }
    }

    /// Nhận cả bản beta (tag có hậu tố như `-beta.1`, đánh dấu pre-release trên GitHub).
    static var includeBetaUpdates: Bool {
        get { defaults.bool(forKey: Key.includeBetaUpdates) }
        set { defaults.set(newValue, forKey: Key.includeBetaUpdates) }
    }

    static var lastUpdateCheck: Date? {
        get { defaults.object(forKey: Key.lastUpdateCheck) as? Date }
        set { defaults.set(newValue, forKey: Key.lastUpdateCheck) }
    }
}

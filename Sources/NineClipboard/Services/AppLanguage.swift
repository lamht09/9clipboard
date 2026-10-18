import AppKit

/// Ngôn ngữ giao diện. Chuỗi nằm trong `Resources/<mã>.lproj` (khoá là câu tiếng Anh).
/// Lưu vào `AppleLanguages` của riêng app — chính là chỗ System Settings › Ngôn ngữ & Vùng › Ứng dụng ghi —
/// nên macOS tự chọn bản dịch lúc khởi động: theo thứ tự ngôn ngữ của máy, không có thì tiếng Anh
/// (`CFBundleDevelopmentRegion`). Đổi ngôn ngữ cần khởi động lại app.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, vi
    case zhHans = "zh-Hans", zhHant = "zh-Hant", ja, ko, es, fr, de, ptBR = "pt-BR", ru, it

    var id: String { rawValue }

    /// Tên ngôn ngữ viết bằng chính ngôn ngữ đó, để ai cũng nhận ra.
    var displayName: String {
        switch self {
        case .system: String(localized: "System Default")
        case .en: "English"
        case .vi: "Tiếng Việt"
        case .zhHans: "简体中文"
        case .zhHant: "繁體中文"
        case .ja: "日本語"
        case .ko: "한국어"
        case .es: "Español"
        case .fr: "Français"
        case .de: "Deutsch"
        case .ptBR: "Português (Brasil)"
        case .ru: "Русский"
        case .it: "Italiano"
        }
    }

    private static let key = "AppleLanguages"
    private static var domain: String { Bundle.main.bundleIdentifier ?? "" }

    /// Lựa chọn đang lưu. Chỉ đọc domain của app: `UserDefaults.standard` trả cả giá trị toàn hệ thống.
    static var current: AppLanguage {
        guard let languages = UserDefaults.standard.persistentDomain(forName: domain)?[key] as? [String],
              let first = languages.first
        else { return .system }
        if let exact = AppLanguage(rawValue: first) { return exact }
        // System Settings có thể ghi kèm vùng ("zh-Hans-VN", "pt-PT"): lấy bản dịch gần nhất cùng ngôn ngữ.
        let codes = allCases.filter { $0 != .system }.map(\.rawValue)
        guard let match = Bundle.preferredLocalizations(from: codes, forPreferences: [first]).first,
              Locale(identifier: match).language.languageCode == Locale(identifier: first).language.languageCode
        else { return .system }
        return AppLanguage(rawValue: match) ?? .system
    }

    static func save(_ language: AppLanguage) {
        if language == .system {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: key)
        }
    }

    /// Bản dịch app sẽ dùng với lựa chọn này.
    var resolvedLocalization: String? {
        let preferences: [String]
        if self == .system {
            preferences = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?[Self.key]
                as? [String] ?? []
        } else {
            preferences = [rawValue]
        }
        return Bundle.preferredLocalizations(from: Bundle.main.localizations, forPreferences: preferences).first
    }

    /// Bản dịch app đang chạy.
    static var running: String? { Bundle.main.preferredLocalizations.first }

    @MainActor
    static func relaunch() {
        NSApp.relaunch()
    }
}

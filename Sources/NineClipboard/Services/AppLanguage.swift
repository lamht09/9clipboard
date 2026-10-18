import AppKit

/// Ngôn ngữ giao diện. Chuỗi nằm trong `Resources/<mã>.lproj` (khoá là câu tiếng Anh).
/// Lưu vào `AppleLanguages` của riêng app — chính là chỗ System Settings › Ngôn ngữ & Vùng › Ứng dụng ghi —
/// nên macOS tự chọn bản dịch lúc khởi động: theo thứ tự ngôn ngữ của máy, không có thì tiếng Anh
/// (`CFBundleDevelopmentRegion`). Đổi ngôn ngữ cần khởi động lại app.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, vi

    var id: String { rawValue }

    /// Tên ngôn ngữ viết bằng chính ngôn ngữ đó, để ai cũng nhận ra.
    var displayName: String {
        switch self {
        case .system: String(localized: "System Default")
        case .en: "English"
        case .vi: "Tiếng Việt"
        }
    }

    private static let key = "AppleLanguages"
    private static var domain: String { Bundle.main.bundleIdentifier ?? "" }

    /// Lựa chọn đang lưu. Chỉ đọc domain của app: `UserDefaults.standard` trả cả giá trị toàn hệ thống.
    static var current: AppLanguage {
        guard let languages = UserDefaults.standard.persistentDomain(forName: domain)?[key] as? [String],
              let first = languages.first
        else { return .system }
        return AppLanguage(rawValue: Locale(identifier: first).language.languageCode?.identifier ?? "") ?? .system
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

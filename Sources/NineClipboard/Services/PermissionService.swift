import AppKit
import ApplicationServices

@MainActor
enum PermissionService {
    private static let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    private static let onboardingShownKey = "onboardingShown"
    private static let missingNoticeShownKey = "missingPermissionNoticeShown"

    static var isTrusted: Bool { AXIsProcessTrusted() }

    static func openSettings() {
        // Gọi kèm prompt để app được thêm sẵn vào danh sách trong System Settings.
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        NSWorkspace.shared.open(settingsURL)
    }

    /// Lần đầu chạy: giải thích lý do cần quyền Accessibility.
    static func showOnboardingIfNeeded() {
        let defaults = UserDefaults.standard
        guard !isTrusted, !defaults.bool(forKey: onboardingShownKey) else { return }
        defaults.set(true, forKey: onboardingShownKey)
        presentPermissionAlert(
            title: "Chào mừng đến với 9clipboard",
            message: """
            Bấm \(Preferences.hotkey.displayString) để mở lịch sử clipboard.

            Để tự dán vào app đang dùng, 9clipboard cần quyền Trợ năng (Accessibility) để gửi phím ⌘V. \
            Nếu không cấp, bạn vẫn dùng được: chọn một mục rồi tự bấm ⌘V.
            """
        )
    }

    /// Khi chọn dán mà chưa có quyền: chỉ copy và nhắc một lần.
    static func noteMissingPermissionOnce() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: missingNoticeShownKey) else { return }
        defaults.set(true, forKey: missingNoticeShownKey)
        presentPermissionAlert(
            title: "Đã copy — bấm ⌘V để dán",
            message: "9clipboard chưa có quyền Trợ năng nên không tự dán được. Cấp quyền để lần sau tự dán."
        )
    }

    private static func presentPermissionAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Mở System Settings")
        alert.addButton(withTitle: "Để sau")
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn {
            openSettings()
        }
    }
}

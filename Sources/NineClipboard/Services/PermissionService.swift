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
            title: String(localized: "Welcome to 9clipboard"),
            message: String(localized: """
            Press \(Preferences.hotkey.displayString) to open your clipboard history.

            To paste into the active app, 9clipboard needs Accessibility access to send ⌘V. \
            Without it you can still pick an item, then press ⌘V yourself.
            """)
        )
    }

    /// Khi chọn dán mà chưa có quyền: chỉ copy và nhắc một lần.
    static func noteMissingPermissionOnce() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: missingNoticeShownKey) else { return }
        defaults.set(true, forKey: missingNoticeShownKey)
        presentPermissionAlert(
            title: String(localized: "Copied — press ⌘V to paste"),
            message: String(localized: "9clipboard can’t paste for you without Accessibility access. Grant it to paste automatically next time.")
        )
    }

    private static func presentPermissionAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: String(localized: "Open System Settings"))
        alert.addButton(withTitle: String(localized: "Later"))
        NSApp.bringToFront()
        if alert.runModal() == .alertFirstButtonReturn {
            openSettings()
        }
    }
}

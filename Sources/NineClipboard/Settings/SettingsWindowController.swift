import AppKit
import SwiftUI

/// Cửa sổ Settings. App là accessory (không có Dock) nên phải tự kích hoạt app khi mở.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let model: SettingsModel
    private var window: NSWindow?

    init(model: SettingsModel) {
        self.model = model
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        model.refresh()
        NSApp.bringToFront()
        window.makeKeyAndOrderFront(nil)
        // Phòng khi app chưa kịp thành active: vẫn đưa cửa sổ lên trên cùng.
        window.orderFrontRegardless()
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: model)))
        window.title = "Cài đặt 9clipboard"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }

    // Quay về từ System Settings (cấp quyền, mục đăng nhập) → đọc lại trạng thái.
    func windowDidBecomeKey(_ notification: Notification) {
        model.refresh()
    }

    func windowWillClose(_ notification: Notification) {
        model.commitAllNames()
    }
}

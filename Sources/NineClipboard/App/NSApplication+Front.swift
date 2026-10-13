import AppKit

extension NSApplication {
    /// Đưa app (accessory, không có Dock) lên trước để cửa sổ/hộp thoại không bị app đang dùng che.
    /// `activate()` từ macOS 14 chỉ là yêu cầu, hệ thống hay từ chối khi gọi từ menu bar → ép kích hoạt.
    func bringToFront() {
        activate(ignoringOtherApps: true)
    }
}

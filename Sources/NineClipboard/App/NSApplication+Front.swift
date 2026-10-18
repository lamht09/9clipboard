import AppKit

extension NSApplication {
    /// Đưa app (accessory, không có Dock) lên trước để cửa sổ/hộp thoại không bị app đang dùng che.
    /// `activate()` từ macOS 14 chỉ là yêu cầu, hệ thống hay từ chối khi gọi từ menu bar → ép kích hoạt.
    func bringToFront() {
        activate(ignoringOtherApps: true)
    }

    /// Mở lại app sau khi tiến trình hiện tại thoát hẳn. `leftover`: thư mục xoá đi trước khi mở lại
    /// (bản cũ sau khi cập nhật).
    func relaunch(removing leftover: URL? = nil) {
        let script = """
            while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do sleep 0.1; done
            [ -n "$1" ] && rm -rf "$1"
            open "$0"
            """
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", script, Bundle.main.bundlePath, leftover?.path ?? ""]
        do {
            try task.run()
            terminate(nil)
        } catch {
            log.error("Không khởi động lại được: \(error.localizedDescription)")
        }
    }
}

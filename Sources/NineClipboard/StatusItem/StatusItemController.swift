import AppKit
import ClipCore

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let privacy: PrivacyController
    private let openPanel: () -> Void

    init(privacy: PrivacyController, openPanel: @escaping () -> Void) {
        self.privacy = privacy
        self.openPanel = openPanel
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        updateIcon()
    }

    /// Icon đổi sang `pause.circle` khi đang tạm dừng (DESIGN §6.3).
    func updateIcon() {
        let paused = privacy.isPaused
        let symbol = paused ? "pause.circle" : "list.clipboard"
        statusItem.button?.image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: paused ? "9clipboard (đang tạm dừng)" : "9clipboard")
        statusItem.button?.appearsDisabled = privacy.skipNext && !paused
    }

    // Dựng lại mỗi lần mở để thời gian còn lại luôn đúng.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let open = ClosureMenuItem(title: "Mở 9clipboard", key: "v") { [openPanel] in
            // Đợi menu đóng hẳn rồi mới mở panel, nếu không panel sẽ mất key ngay.
            DispatchQueue.main.async { openPanel() }
        }
        open.keyEquivalentModifierMask = [.option]
        menu.addItem(open)
        menu.addItem(.separator())

        if let until = privacy.pausedUntil {
            let status = NSMenuItem(title: Self.pauseStatus(until: until), action: nil, keyEquivalent: "")
            status.isEnabled = false
            menu.addItem(status)
            menu.addItem(ClosureMenuItem(title: "Tiếp tục ghi") { [privacy] in privacy.resume() })
        } else {
            let pause = NSMenuItem(title: "Tạm dừng ghi", action: nil, keyEquivalent: "")
            let sub = NSMenu()
            sub.addItem(ClosureMenuItem(title: "15 phút") { [privacy] in privacy.pause(for: 15 * 60) })
            sub.addItem(ClosureMenuItem(title: "1 giờ") { [privacy] in privacy.pause(for: 60 * 60) })
            sub.addItem(ClosureMenuItem(title: "Đến khi bật lại") { [privacy] in privacy.pause(for: nil) })
            pause.submenu = sub
            menu.addItem(pause)

            let skip = ClosureMenuItem(title: "Bỏ qua lần copy tiếp theo") { [privacy] in privacy.toggleSkipNext() }
            skip.state = privacy.skipNext ? .on : .off
            menu.addItem(skip)
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Thoát", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private static func pauseStatus(until: Date) -> String {
        guard until != .distantFuture else { return "Đang tạm dừng" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm"
        return "Đang tạm dừng đến \(formatter.string(from: until))"
    }
}

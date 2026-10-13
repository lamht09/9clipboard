import AppKit
import ClipCore

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let openPanel: () -> Void

    init(openPanel: @escaping () -> Void) {
        self.openPanel = openPanel
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "9clipboard")
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let open = NSMenuItem(title: "Mở 9clipboard", action: #selector(openPanelAction), keyEquivalent: "v")
        open.keyEquivalentModifierMask = [.option]
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Thoát", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func openPanelAction() {
        // Đợi menu đóng hẳn rồi mới mở panel, nếu không panel sẽ mất key ngay.
        DispatchQueue.main.async { self.openPanel() }
    }
}

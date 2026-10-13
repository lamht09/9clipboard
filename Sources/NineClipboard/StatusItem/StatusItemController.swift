import AppKit
import ClipCore

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let model: AppModel

    init(model: AppModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "9clipboard")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // Tạm thời (M1): hiện 10 mục gần nhất để kiểm tra trước khi có panel.
        for item in model.items.prefix(10) {
            let title = (item.plainText ?? "(\(item.kind.rawValue))")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ⏎ ")
            let menuItem = NSMenuItem(title: String(title.prefix(50)), action: #selector(copyItem(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = item
            menuItem.toolTip = item.sourceAppName
            if let app = item.sourceAppName {
                menuItem.title += "  — \(app)"
            }
            menu.addItem(menuItem)
        }
        if model.items.isEmpty {
            menu.addItem(withTitle: "Chưa có gì", action: nil, keyEquivalent: "")
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Thoát", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func copyItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipItem, let text = item.plainText else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        pb.setData(Data(), forType: NSPasteboard.PasteboardType(UTI.selfMarker))
        if let id = item.id {
            Task {
                try? await model.store.markUsed(id: id)
                await model.reload()
            }
        }
    }
}

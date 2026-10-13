import AppKit
import Carbon.HIToolbox
import ClipCore
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    static let height = PanelLayout.height
    static let maxWidth: CGFloat = 1100
    static let margin: CGFloat = 12

    private let panel = ClipPanel()
    let viewModel: PanelViewModel
    private let model: AppModel
    private(set) var isShown = false

    init(model: AppModel) {
        self.model = model
        viewModel = PanelViewModel(model: model)
        super.init()

        // Panel trong suốt: không nền, không khung — chỉ các thẻ tự vẽ nền của mình.
        let hosting = NSHostingView(rootView: PanelRootView(viewModel: viewModel))
        hosting.sizingOptions = []
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = .clear
        panel.contentView = hosting
        panel.delegate = self
        panel.keyHandler = { [weak self] event in self?.handleKey(event) ?? false }
        panel.scrollHandler = { [weak self] event in self?.viewModel.scroll(with: event) }
        viewModel.onPick = { [weak self] item, plainOnly in self?.paste(item, plainOnly: plainOnly) }
    }

    /// Ghi item lên pasteboard, đóng panel rồi gửi ⌘V (DESIGN §5.2).
    private func paste(_ item: ClipItem, plainOnly: Bool) {
        guard let id = item.id else { return }
        Task {
            let reps = (try? await model.store.representations(itemID: id)) ?? []
            let blobs = model.store.blobs
            PasteService.write(item, representations: reps, blobLoader: blobs.load, plainOnly: plainOnly)
            // Đóng ngay (không animation) để panel nhả bàn phím trước khi ⌘V được gửi.
            hide(animated: false)
            if Preferences.autoPaste {
                if PermissionService.isTrusted {
                    PasteService.sendPasteKeystroke()
                } else {
                    PermissionService.noteMissingPermissionOnce()
                }
            }
            try? await model.store.markUsed(id: id)
            await model.reload()
        }
    }

    func toggle() {
        isShown ? hide() : show()
    }

    func show() {
        guard !isShown else { return }
        isShown = true
        viewModel.resetForOpen()
        Task { await model.reload() }

        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        let width = min(visible.width - Self.margin * 2, Self.maxWidth)
        let target = NSRect(
            x: visible.midX - width / 2,
            y: visible.minY + Self.margin,
            width: width,
            height: Self.height
        )
        var start = target
        start.origin.y = visible.minY - Self.height

        panel.setFrame(start, display: false)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(target, display: true)
            panel.animator().alphaValue = 1
        }
    }

    func hide(animated: Bool = true) {
        guard isShown else { return }
        isShown = false
        guard animated else {
            panel.orderOut(nil)
            return
        }
        var end = panel.frame
        end.origin.y -= Self.height / 2
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(end, display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: { [panel] in
            MainActor.assumeIsolated {
                if !self.isShown { panel.orderOut(nil) }
            }
        })
    }

    // Click ra ngoài panel → đóng.
    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    // MARK: - Menu ghim (⌘P)

    /// Menu chọn Pinboard, hiện ngay dưới đầu thẻ đang chọn.
    private func showPinMenu() {
        guard let item = viewModel.selectedItem, let view = panel.contentView else { return }
        let menu = NSMenu()
        menu.autoenablesItems = false
        let boards = viewModel.pinboards
        for (i, board) in boards.enumerated() {
            let entry = ClosureMenuItem(title: board.name, key: i < 9 ? "\(i + 1)" : "") { [viewModel] in
                viewModel.pin(item, to: board)
            }
            entry.state = board.id == item.pinboardID ? .on : .off
            entry.image = Self.dot(hex: board.color)
            menu.addItem(entry)
        }
        if boards.isEmpty {
            // Chưa có bảng nào: mục đầu tiên tạo luôn bảng mặc định.
            menu.addItem(ClosureMenuItem(title: ClipboardStore.defaultPinboardName, key: "1") { [model] in
                Task { await model.createPinboard(name: ClipboardStore.defaultPinboardName, pinning: item) }
            })
        }
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: "Bảng mới…", key: "n") { [viewModel] in
            viewModel.startCreatingBoard(pinning: item)
        })
        if item.isPinned {
            menu.addItem(ClosureMenuItem(title: "Bỏ ghim", key: "\u{8}") { [viewModel] in viewModel.unpin(item) })
        }

        let cardX = StripLayout.cardX(viewModel.selectedIndex) - viewModel.scrollOffset
        let cardTop = PanelLayout.barTop + PanelLayout.barHeight + StripLayout.verticalInset + 24
        let point = NSPoint(x: cardX + 8, y: view.isFlipped ? cardTop : view.bounds.height - cardTop)
        menu.popUp(positioning: nil, at: point, in: view)
    }

    private static func dot(hex: String) -> NSImage {
        NSImage(size: NSSize(width: 10, height: 10), flipped: false) { rect in
            NSColor(Color(hex: hex)).setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
    }

    // MARK: - Bàn phím (DESIGN §6.2)

    private func handleKey(_ event: NSEvent) -> Bool {
        // Bộ gõ đang soạn chữ (ví dụ Telex của hệ thống): để ô tìm kiếm tự xử lý Enter/Esc/mũi tên.
        if let editor = panel.firstResponder as? NSTextView, editor.hasMarkedText() { return false }

        // Đang nhập tên Pinboard: chỉ bắt Enter/Esc, các phím khác vào ô nhập.
        if viewModel.boardEditor != nil {
            switch Int(event.keyCode) {
            case kVK_Return, kVK_ANSI_KeypadEnter: viewModel.commitBoardEditor()
            case kVK_Escape: viewModel.cancelBoardEditor()
            default: return false
            }
            return true
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let cmd = flags.contains(.command)
        let shift = flags.contains(.shift)

        switch Int(event.keyCode) {
        case kVK_LeftArrow:
            cmd && viewModel.canReorder ? viewModel.moveSelectedPin(by: -1) : viewModel.move(by: -1)
        case kVK_RightArrow:
            cmd && viewModel.canReorder ? viewModel.moveSelectedPin(by: 1) : viewModel.move(by: 1)
        case kVK_ANSI_P where cmd:
            showPinMenu()
        case kVK_Tab:
            viewModel.cycleFilter(by: shift ? -1 : 1)
        case kVK_Escape:
            // Lần đầu xoá ô tìm kiếm, lần hai mới đóng.
            if viewModel.query.isEmpty { hide() } else { viewModel.query = "" }
        case kVK_Return, kVK_ANSI_KeypadEnter:
            viewModel.pick(plainOnly: shift)
        case kVK_Delete where cmd:
            viewModel.deleteSelected()
        default:
            if cmd, let digit = event.charactersIgnoringModifiers.flatMap(Int.init), (1...9).contains(digit) {
                viewModel.pick(at: digit - 1)
                return true
            }
            return false
        }
        return true
    }
}

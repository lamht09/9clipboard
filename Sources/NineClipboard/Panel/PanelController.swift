import AppKit
import Carbon.HIToolbox
import ClipCore
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    static let height: CGFloat = 300
    static let margin: CGFloat = 12

    private let panel = ClipPanel()
    let viewModel: PanelViewModel
    private let model: AppModel
    private(set) var isShown = false

    init(model: AppModel) {
        self.model = model
        viewModel = PanelViewModel(model: model)
        super.init()

        let effect = NSVisualEffectView()
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 16
        effect.layer?.masksToBounds = true

        let hosting = NSHostingView(rootView: PanelRootView(viewModel: viewModel))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        effect.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: effect.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: effect.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: effect.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: effect.bottomAnchor),
        ])
        panel.contentView = effect
        panel.delegate = self
        panel.keyHandler = { [weak self] event in self?.handleKey(event) ?? false }
        viewModel.onPick = { [weak self] item, plainOnly in self?.paste(item, plainOnly: plainOnly) }
    }

    /// Ghi item lên pasteboard, đóng panel rồi gửi ⌘V (DESIGN §5.2).
    private func paste(_ item: ClipItem, plainOnly: Bool) {
        guard let id = item.id else { return }
        Task {
            let reps = (try? await model.store.representations(itemID: id)) ?? []
            PasteService.write(item, representations: reps, plainOnly: plainOnly)
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
        let target = NSRect(
            x: visible.minX + Self.margin,
            y: visible.minY + Self.margin,
            width: visible.width - Self.margin * 2,
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

    // MARK: - Bàn phím (DESIGN §6.2)

    private func handleKey(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let cmd = flags.contains(.command)
        let shift = flags.contains(.shift)

        switch Int(event.keyCode) {
        case kVK_LeftArrow:
            viewModel.move(by: -1)
        case kVK_RightArrow:
            viewModel.move(by: 1)
        case kVK_Escape:
            hide()
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

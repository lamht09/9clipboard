import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Ô ghi phím tắt tự làm (thay `KeyboardShortcuts.Recorder`, xem STATE.md).
/// Bấm vào ô → bấm tổ hợp mới; `Esc` hoặc click ra ngoài để huỷ.
struct ShortcutRecorder: NSViewRepresentable {
    var model: SettingsModel

    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.onBegin = { [model] in model.beginRecording() }
        button.onEnd = { [model] in model.endRecording() }
        button.onRecord = { [model] in model.record($0) }
        return button
    }

    func updateNSView(_ button: RecorderButton, context: Context) {
        button.shortcut = model.shortcut
    }
}

final class RecorderButton: NSButton {
    var onBegin: () -> Void = {}
    var onEnd: () -> Void = {}
    /// Trả về true nếu nhận tổ hợp (kết thúc ghi), false thì tiếp tục chờ.
    var onRecord: (HotkeyManager.Shortcut) -> Bool = { _ in true }

    var shortcut: HotkeyManager.Shortcut? {
        didSet { updateTitle() }
    }

    private var isRecording = false {
        didSet { updateTitle() }
    }

    init() {
        super.init(frame: .zero)
        bezelStyle = .push
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(startRecording)
        widthAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true
        updateTitle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }

    @objc private func startRecording() {
        guard !isRecording else { return }
        window?.makeFirstResponder(self)
        isRecording = true
        onBegin()
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        onEnd()
    }

    override func resignFirstResponder() -> Bool {
        stopRecording()
        return super.resignFirstResponder()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil { stopRecording() }
        super.viewWillMove(toWindow: newWindow)
    }

    // Tổ hợp có ⌘ đi qua performKeyEquivalent trước keyDown.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording, event.type == .keyDown else { return super.performKeyEquivalent(with: event) }
        handle(event)
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return super.keyDown(with: event) }
        handle(event)
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if Int(event.keyCode) == kVK_Escape, flags.isEmpty {
            window?.makeFirstResponder(nil)
            return
        }
        if onRecord(HotkeyManager.Shortcut(event: event)) {
            window?.makeFirstResponder(nil)
        } else {
            NSSound.beep()
        }
    }

    private func updateTitle() {
        title = isRecording ? String(localized: "Press a shortcut…") : (shortcut?.displayString ?? String(localized: "Not Set"))
    }
}

import AppKit
import Carbon.HIToolbox

/// Phím tắt toàn cục qua Carbon `RegisterEventHotKey` (không cần quyền).
/// Thay cho thư viện KeyboardShortcuts — xem docs/STATE.md.
@MainActor
final class HotkeyManager {
    struct Shortcut: Equatable, Codable {
        var keyCode: UInt32
        /// Modifier kiểu Carbon (`optionKey`, `cmdKey`, …)
        var modifiers: UInt32

        static let `default` = Shortcut(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(optionKey))
    }

    static let shared = HotkeyManager()

    private static let signature: OSType = 0x3943_4C50 // "9CLP"
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var action: (() -> Void)?

    private(set) var shortcut: Shortcut?

    /// Đăng ký phím tắt. Trả về false nếu hệ thống từ chối (ví dụ đã bị app khác giữ).
    @discardableResult
    func register(_ shortcut: Shortcut, action: @escaping () -> Void) -> Bool {
        unregister()
        installHandlerIfNeeded()
        self.action = action

        let id = EventHotKeyID(signature: Self.signature, id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, id, GetEventDispatcherTarget(), 0, &ref)
        guard status == noErr, let ref else {
            log.error("RegisterEventHotKey failed: \(status)")
            return false
        }
        hotKeyRef = ref
        self.shortcut = shortcut
        return true
    }

    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        hotKeyRef = nil
        shortcut = nil
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, _ in
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            guard id.signature == HotkeyManager.signature else { return OSStatus(eventNotHandledErr) }
            // Carbon gọi handler trên main thread.
            MainActor.assumeIsolated { HotkeyManager.shared.action?() }
            return noErr
        }, 1, &spec, nil, &handlerRef)
    }
}

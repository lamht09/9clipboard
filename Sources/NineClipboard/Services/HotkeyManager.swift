import AppKit
import Carbon.HIToolbox

/// Phím tắt toàn cục qua Carbon `RegisterEventHotKey` (không cần quyền).
/// Thay cho thư viện KeyboardShortcuts: thư viện đó dùng `@State`, không build được khi chỉ có Command Line Tools.
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
    /// Gọi khi bấm phím tắt (mở/đóng panel).
    var action: (() -> Void)?

    /// Phím tắt đang dùng (vẫn giữ khi tạm tắt lúc ghi phím mới).
    private(set) var shortcut: Shortcut?

    /// Đăng ký phím tắt thay cho phím cũ. Trả về false nếu hệ thống từ chối (ví dụ đã bị app khác giữ);
    /// khi đó không còn phím nào được đăng ký.
    @discardableResult
    func register(_ shortcut: Shortcut) -> Bool {
        unregister()
        guard registerCarbon(shortcut) else { return false }
        self.shortcut = shortcut
        return true
    }

    func unregister() {
        suspend()
        shortcut = nil
    }

    /// Tạm tắt (khi đang ghi phím tắt mới trong Settings, để bấm thử không mở panel).
    func suspend() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        hotKeyRef = nil
    }

    func resume() {
        guard hotKeyRef == nil, let shortcut else { return }
        _ = registerCarbon(shortcut)
    }

    private func registerCarbon(_ shortcut: Shortcut) -> Bool {
        installHandlerIfNeeded()
        let id = EventHotKeyID(signature: Self.signature, id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, id, GetEventDispatcherTarget(), 0, &ref)
        guard status == noErr, let ref else {
            log.error("RegisterEventHotKey failed: \(status)")
            return false
        }
        hotKeyRef = ref
        return true
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

// MARK: - Chuyển đổi và hiển thị

extension HotkeyManager.Shortcut {
    /// Từ sự kiện phím trong ô ghi phím. Bỏ qua Caps Lock, Fn.
    init(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var carbon = 0
        if flags.contains(.command) { carbon |= cmdKey }
        if flags.contains(.option) { carbon |= optionKey }
        if flags.contains(.control) { carbon |= controlKey }
        if flags.contains(.shift) { carbon |= shiftKey }
        self.init(keyCode: UInt32(event.keyCode), modifiers: UInt32(carbon))
    }

    var modifierFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if modifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if modifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        if modifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        return flags
    }

    /// Có ít nhất một trong ⌘ ⌥ ⌃ (chỉ ⇧ thì sẽ chặn mất việc gõ chữ hoa). Phím F1–F20 đứng một mình cũng được.
    var isUsable: Bool {
        let strong = UInt32(cmdKey | optionKey | controlKey)
        return modifiers & strong != 0 || Self.functionKeys.keys.contains(Int(keyCode))
    }

    /// Ví dụ "⌥V", "⌃⇧Space".
    var displayString: String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        return s + keyName
    }

    /// Ký tự dùng cho `NSMenuItem.keyEquivalent` (chữ thường). Rỗng nếu là phím đặc biệt.
    var menuKeyEquivalent: String {
        Self.specialKeys[Int(keyCode)] == nil && Self.functionKeys[Int(keyCode)] == nil ? keyName.lowercased() : ""
    }

    var keyName: String {
        let code = Int(keyCode)
        if let name = Self.specialKeys[code] ?? Self.functionKeys[code] { return name }
        return Self.translate(code)?.uppercased() ?? "#\(code)"
    }

    private static let specialKeys: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_Escape: "⎋", kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟", kVK_ANSI_KeypadEnter: "⌤",
    ]

    private static let functionKeys: [Int: String] = [
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7",
        kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12", kVK_F13: "F13",
        kVK_F14: "F14", kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17", kVK_F18: "F18", kVK_F19: "F19",
        kVK_F20: "F20",
    ]

    /// Ký tự của phím theo bàn phím ASCII hiện tại (không modifier).
    private static func translate(_ keyCode: Int) -> String? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let layoutData = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue() as Data
        var deadKeys: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        let status = layoutData.withUnsafeBytes { buffer in
            UCKeyTranslate(
                buffer.bindMemory(to: UCKeyboardLayout.self).baseAddress, UInt16(keyCode),
                UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeys, chars.count, &length, &chars)
        }
        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }

    /// Tổ hợp hay bị dùng sẵn (hệ thống hoặc menu của hầu hết app): cảnh báo trước khi nhận.
    var knownConflict: String? {
        let cmd = UInt32(cmdKey), shift = UInt32(shiftKey), ctrl = UInt32(controlKey)
        let table: [(Int, UInt32, String)] = [
            (kVK_ANSI_C, cmd, "Copy"), (kVK_ANSI_V, cmd, "Paste"), (kVK_ANSI_X, cmd, "Cut"),
            (kVK_ANSI_Z, cmd, "Undo"), (kVK_ANSI_A, cmd, "Select All"), (kVK_ANSI_S, cmd, "Save"),
            (kVK_ANSI_Q, cmd, "Quit App"), (kVK_ANSI_W, cmd, "Close Window"), (kVK_ANSI_T, cmd, "New Tab"),
            (kVK_ANSI_N, cmd, "New Window"), (kVK_ANSI_F, cmd, "Find"), (kVK_ANSI_P, cmd, "Print"),
            (kVK_ANSI_H, cmd, "Hide App"), (kVK_ANSI_M, cmd, "Minimize"), (kVK_Tab, cmd, "Switch Apps"),
            (kVK_Space, cmd, "Spotlight"), (kVK_Space, ctrl, "Switch Input Source"),
            (kVK_ANSI_V, cmd | shift, "Paste and Match Style (Slack, Google Docs, Notion…)"),
            (kVK_ANSI_3, cmd | shift, "Screenshot"), (kVK_ANSI_4, cmd | shift, "Screenshot"),
            (kVK_ANSI_5, cmd | shift, "Screenshot"),
        ]
        return table.first { $0.0 == Int(keyCode) && $0.1 == modifiers }.map { NSLocalizedString($0.2, comment: "") }
    }
}

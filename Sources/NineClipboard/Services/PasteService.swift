import AppKit
import Carbon.HIToolbox
import ClipCore

@MainActor
enum PasteService {
    /// Ghi item lên pasteboard kèm marker để `ClipboardMonitor` bỏ qua.
    /// `plainOnly`: chỉ ghi `public.utf8-plain-text`, bỏ định dạng (ảnh không có text thì vẫn dán ảnh).
    static func write(_ item: ClipItem, representations: [Representation], blobLoader: (String) -> Data? = { _ in nil }, plainOnly: Bool) {
        let pb = NSPasteboard.general
        pb.clearContents()

        if plainOnly, let text = item.plainText {
            pb.setString(text, forType: .string)
        } else {
            for rep in representations {
                let data = rep.data ?? rep.blobPath.flatMap(blobLoader)
                if let data {
                    pb.setData(data, forType: NSPasteboard.PasteboardType(rep.uti))
                }
            }
            if representations.isEmpty, let text = item.plainText {
                pb.setString(text, forType: .string)
            }
        }
        pb.setData(Data(), forType: NSPasteboard.PasteboardType(UTI.selfMarker))
    }

    /// Gửi ⌘V tới app đang frontmost sau `delay`. Cần quyền Accessibility.
    static func sendPasteKeystroke(after delay: Duration = .milliseconds(50)) {
        Task { @MainActor in
            try? await Task.sleep(for: delay)
            let source = CGEventSource(stateID: .combinedSessionState)
            let key = CGKeyCode(kVK_ANSI_V)
            let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
            let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
            // Đặt cờ tường minh: bỏ qua ⇧/⌥ người dùng có thể đang giữ.
            down?.flags = .maskCommand
            up?.flags = .maskCommand
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
    }
}

import AppKit
import SwiftUI

/// Ô nhập của thanh tìm kiếm. Dùng `NSTextField` thay cho `TextField` của SwiftUI: `TextField` có lúc
/// không cập nhật binding khi bộ gõ (tiếng Trung, Nhật, Hàn…) chốt chữ, làm chuỗi tìm lệch với chữ đang hiện.
/// Chữ đang soạn dở trong bộ gõ chưa được tính là chuỗi tìm; chốt xong mới lọc.
struct SearchField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    /// Đổi giá trị thì ô lấy lại focus (mỗi lần mở panel).
    var focusToken: Int

    func makeNSView(context: Context) -> SearchTextField {
        let field = SearchTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 12.5)
        field.placeholderString = placeholder
        field.lineBreakMode = .byClipping
        field.cell?.isScrollable = true
        field.cell?.wraps = false
        // Chuỗi dài không được đẩy rộng thanh tìm kiếm.
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ field: SearchTextField, context: Context) {
        let coordinator = context.coordinator
        coordinator.text = $text
        // Không ghi đè khi đang soạn chữ: sẽ xoá mất phần bộ gõ chưa chốt.
        if field.stringValue != text, !field.isComposing {
            field.stringValue = text
        }
        if coordinator.focusToken != focusToken {
            coordinator.focusToken = focusToken
            Task { @MainActor [weak field] in
                guard let field, let window = field.window, window.firstResponder !== field.currentEditor() else { return }
                window.makeFirstResponder(field)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var focusToken: Int?

        init(text: Binding<String>) { self.text = text }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? SearchTextField else { return }
            sync(field)
            // Bộ gõ có thể báo thay đổi trước khi bỏ đánh dấu phần vừa chốt: kiểm tra lại ở vòng sau.
            if field.isComposing {
                Task { @MainActor [weak self, weak field] in
                    guard let self, let field else { return }
                    self.sync(field)
                }
            }
        }

        private func sync(_ field: SearchTextField) {
            guard !field.isComposing, text.wrappedValue != field.stringValue else { return }
            text.wrappedValue = field.stringValue
        }
    }
}

final class SearchTextField: NSTextField {
    /// Bộ gõ đang soạn chữ (còn phần gạch chân chưa chốt).
    var isComposing: Bool {
        (currentEditor() as? NSTextView)?.hasMarkedText() ?? false
    }

    /// App chạy trên menu bar, không có menu Edit nên ⌘V/⌘C/⌘X/⌘A không tự tới ô nhập: tự chuyển cho nó.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
              let editor = currentEditor() as? NSTextView, !isComposing
        else { return super.performKeyEquivalent(with: event) }
        switch event.charactersIgnoringModifiers {
        case "v": editor.pasteAsPlainText(nil)
        case "c": editor.copy(nil)
        case "x": editor.cut(nil)
        case "a": editor.selectAll(nil)
        default: return super.performKeyEquivalent(with: event)
        }
        return true
    }
}

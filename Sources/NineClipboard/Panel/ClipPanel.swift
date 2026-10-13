import AppKit

/// Panel nổi không kích hoạt app: nhận bàn phím nhưng app đang dùng vẫn là frontmost.
final class ClipPanel: NSPanel {
    /// Trả về true nếu đã xử lý phím (khi đó sự kiện không đi tiếp).
    var keyHandler: ((NSEvent) -> Bool)?
    /// Nhận mọi sự kiện cuộn (con lăn, trackpad) trong panel.
    var scrollHandler: ((NSEvent) -> Void)?

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        hidesOnDeactivate = false
        isMovable = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, keyHandler?(event) == true { return }
        if event.type == .scrollWheel, let scrollHandler {
            scrollHandler(event)
            return
        }
        super.sendEvent(event)
    }
}

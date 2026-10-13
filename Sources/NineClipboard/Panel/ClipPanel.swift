import AppKit

/// Panel nổi không kích hoạt app: nhận bàn phím nhưng app đang dùng vẫn là frontmost.
final class ClipPanel: NSPanel {
    /// Trả về true nếu đã xử lý phím (khi đó sự kiện không đi tiếp).
    var keyHandler: ((NSEvent) -> Bool)?

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
        if event.type == .scrollWheel, let horizontal = Self.verticalToHorizontal(event) {
            super.sendEvent(horizontal)
            return
        }
        super.sendEvent(event)
    }

    /// Dải thẻ cuộn ngang, nên đổi cuộn dọc (con lăn chuột) thành cuộn ngang.
    private static func verticalToHorizontal(_ event: NSEvent) -> NSEvent? {
        guard abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX),
              let cg = event.cgEvent?.copy() else { return nil }
        let pairs: [(CGEventField, CGEventField)] = [
            (.scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2),
            (.scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis2),
            (.scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2),
        ]
        for (vertical, horizontal) in pairs {
            cg.setDoubleValueField(horizontal, value: cg.getDoubleValueField(vertical))
            cg.setDoubleValueField(vertical, value: 0)
        }
        return NSEvent(cgEvent: cg)
    }
}

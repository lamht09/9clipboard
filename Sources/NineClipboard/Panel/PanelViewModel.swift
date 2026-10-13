import ClipCore
import AppKit
import SwiftUI
import Observation

/// Trạng thái hiển thị của panel (thay cho @State — xem STATE.md).
@MainActor
@Observable
final class PanelViewModel {
    private let model: AppModel
    var selectedIndex = 0

    // MARK: Cuộn — tự quản lý thay cho ScrollView (ScrollView không nhận con lăn chuột khi cuộn ngang).
    /// Khoảng đã cuộn sang phải, tính bằng point.
    var scrollOffset: CGFloat = 0
    /// Bề rộng vùng nhìn thấy, do view báo lên.
    var viewportWidth: CGFloat = 0
    @ObservationIgnored private var dragStartOffset: CGFloat?
    @ObservationIgnored private var lastDragEnd = Date.distantPast

    /// Callback khi người dùng chọn dán (M3 nối vào PasteService).
    var onPick: ((ClipItem, _ plainOnly: Bool) -> Void)?

    init(model: AppModel) {
        self.model = model
    }

    var items: [ClipItem] { model.items }

    var selectedItem: ClipItem? {
        items.indices.contains(selectedIndex) ? items[selectedIndex] : nil
    }

    func resetForOpen() {
        selectedIndex = 0
        scrollOffset = 0
    }

    func move(by delta: Int) {
        guard !items.isEmpty else { return }
        selectedIndex = min(max(selectedIndex + delta, 0), items.count - 1)
        // Điều hướng phím: đưa thẻ đang chọn vào giữa (rê chuột chọn thì không cuộn).
        let center = StripLayout.cardX(selectedIndex) + StripLayout.cardSize / 2
        withAnimation(.easeOut(duration: 0.15)) {
            scrollOffset = clamped(center - viewportWidth / 2)
        }
    }

    // MARK: - Cuộn

    var maxOffset: CGFloat {
        max(0, StripLayout.contentWidth(count: items.count) - viewportWidth)
    }

    func clamped(_ offset: CGFloat) -> CGFloat {
        min(max(offset, 0), maxOffset)
    }

    /// Chỉ số các thẻ cần vẽ, có thêm vùng đệm 1 màn hình mỗi bên để animation không bị hụt thẻ.
    func visibleRange() -> Range<Int> {
        guard !items.isEmpty else { return 0..<0 }
        let buffer = viewportWidth
        let first = Int(((scrollOffset - buffer - StripLayout.inset) / StripLayout.step).rounded(.down))
        let last = Int(((scrollOffset + viewportWidth + buffer) / StripLayout.step).rounded(.up))
        return max(first, 0)..<min(max(last, 0), items.count)
    }

    /// Con lăn chuột hoặc trackpad. Cuộn dọc cũng được tính là cuộn ngang.
    func scroll(with event: NSEvent) {
        let dx = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) ? event.scrollingDeltaX : event.scrollingDeltaY
        guard dx != 0 else { return }
        if event.hasPreciseScrollingDeltas {
            scrollOffset = clamped(scrollOffset - dx)
        } else {
            // Con lăn chuột thường: mỗi nấc ≈ nửa thẻ.
            withAnimation(.easeOut(duration: 0.12)) {
                scrollOffset = clamped(scrollOffset - dx * StripLayout.step / 2)
            }
        }
    }

    func dragChanged(translation: CGFloat) {
        let start = dragStartOffset ?? scrollOffset
        dragStartOffset = start
        scrollOffset = clamped(start - translation)
    }

    /// Thả chuột: trượt tiếp theo quán tính.
    func dragEnded(predictedTranslation: CGFloat) {
        let start = dragStartOffset ?? scrollOffset
        dragStartOffset = nil
        lastDragEnd = Date()
        withAnimation(.easeOut(duration: 0.35)) {
            scrollOffset = clamped(start - predictedTranslation)
        }
    }

    func select(_ item: ClipItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            selectedIndex = index
        }
    }

    /// Click chuột: bỏ qua nếu đó là lúc thả chuột sau khi kéo, để kéo không bị dán nhầm.
    func click(_ item: ClipItem) {
        guard dragStartOffset == nil, Date().timeIntervalSince(lastDragEnd) > 0.2 else { return }
        pick(item)
    }

    func pick(_ item: ClipItem? = nil, plainOnly: Bool = false) {
        guard let item = item ?? selectedItem else { return }
        onPick?(item, plainOnly)
    }

    func pick(at index: Int) {
        guard items.indices.contains(index) else { return }
        selectedIndex = index
        pick(items[index])
    }

    func deleteSelected() {
        guard let item = selectedItem else { return }
        Task {
            await model.delete(item)
            selectedIndex = min(selectedIndex, max(items.count - 1, 0))
        }
    }
}

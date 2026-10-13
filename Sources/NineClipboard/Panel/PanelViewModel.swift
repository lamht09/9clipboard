import ClipCore
import Foundation
import Observation

/// Trạng thái hiển thị của panel (thay cho @State — xem STATE.md).
@MainActor
@Observable
final class PanelViewModel {
    private let model: AppModel
    var selectedIndex = 0
    /// Tăng mỗi lần mở panel để view cuộn về đầu.
    var openToken = 0

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
        openToken += 1
    }

    func move(by delta: Int) {
        guard !items.isEmpty else { return }
        selectedIndex = min(max(selectedIndex + delta, 0), items.count - 1)
    }

    func select(_ item: ClipItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            selectedIndex = index
        }
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

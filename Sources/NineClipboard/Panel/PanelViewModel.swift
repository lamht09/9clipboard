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

    // MARK: Tìm kiếm và lọc (DESIGN §7)
    /// Nội dung ô tìm kiếm; kết quả chỉ cập nhật sau 80ms ngừng gõ (`activeQuery`).
    var query = "" {
        didSet { if query != oldValue { scheduleSearch() } }
    }
    private(set) var activeQuery = ""
    var filter: ClipFilter = .all {
        didSet { if filter != oldValue { resetPosition() } }
    }
    /// Tăng mỗi lần mở panel để ô tìm kiếm lấy lại focus.
    private(set) var focusToken = 0
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private let engine = SearchEngine()
    @ObservationIgnored private var cachedKey: ResultKey?
    @ObservationIgnored private var cachedItems: [ClipItem] = []

    // MARK: Pinboard (M6)
    /// Ô nhập tên bảng ngay trên thanh tab (tạo mới hoặc đổi tên). Không dùng NSAlert vì nó
    /// phải kích hoạt app, làm app đang dùng mất focus.
    var boardEditor: BoardEditor?
    /// Thẻ đang được kéo để sắp xếp lại trong tab Pinboard.
    private(set) var reorderIndex: Int?
    private(set) var reorderTranslation: CGFloat = 0

    struct BoardEditor {
        enum Mode {
            case create(pinning: ClipItem?)
            case rename(Pinboard)
        }
        var mode: Mode
        var name: String
    }

    private struct ResultKey: Equatable {
        var revision: Int
        var query: String
        var filter: ClipFilter
    }

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

    /// Các thẻ đang hiện: lịch sử sau khi lọc theo tab và xếp hạng theo chuỗi tìm.
    var items: [ClipItem] {
        let key = ResultKey(revision: model.revision, query: activeQuery, filter: filter)
        if key != cachedKey {
            cachedItems = engine.search(model.items, query: key.query, filter: key.filter).map(\.item)
            cachedKey = key
        }
        return cachedItems
    }

    var emptyMessage: String {
        if !activeQuery.isEmpty { return "Không tìm thấy “\(activeQuery)”" }
        if model.items.isEmpty { return "Chưa có gì trong lịch sử. Hãy copy thứ gì đó." }
        if case .pinboard = filter { return "Bảng này chưa có mục nào. Chọn thẻ rồi bấm ⌘P để ghim." }
        return "Không có mục nào ở tab \(filter.label)"
    }
    var previews: PreviewCache { model.previews }
    var pinboards: [Pinboard] { model.pinboards }

    /// Các tab theo thứ tự `Tab`: theo loại, rồi tới từng Pinboard.
    var filters: [ClipFilter] {
        ClipFilter.kinds + pinboards.compactMap { $0.id.map(ClipFilter.pinboard) }
    }

    func pinboard(for item: ClipItem) -> Pinboard? { model.pinboard(id: item.pinboardID) }

    func label(for filter: ClipFilter) -> String {
        if case .pinboard(let id) = filter { return model.pinboard(id: id)?.name ?? filter.label }
        return filter.label
    }

    /// Kéo thẻ để sắp xếp chỉ có ở tab Pinboard và khi không tìm kiếm (thứ tự lúc đó là `pin_order`).
    var canReorder: Bool {
        if case .pinboard = filter, activeQuery.isEmpty { return true }
        return false
    }

    var selectedItem: ClipItem? {
        items.indices.contains(selectedIndex) ? items[selectedIndex] : nil
    }

    func resetForOpen() {
        query = ""
        filter = .all
        boardEditor = nil
        resetPosition()
        focusToken += 1
    }

    private func resetPosition() {
        selectedIndex = 0
        scrollOffset = 0
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let pending = query
        // Xoá hết thì hiện lại toàn bộ ngay, không chờ debounce.
        guard !pending.trimmingCharacters(in: .whitespaces).isEmpty else {
            applyQuery("")
            return
        }
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            self?.applyQuery(pending)
        }
    }

    private func applyQuery(_ value: String) {
        guard value != activeQuery else { return }
        activeQuery = value
        resetPosition()
    }

    /// `Tab` / `⇧Tab`: chuyển vòng qua các tab lọc.
    func cycleFilter(by delta: Int) {
        let all = filters
        let index = all.firstIndex(of: filter) ?? 0
        filter = all[(index + delta + all.count) % all.count]
    }

    // MARK: - Ghim

    func pin(_ item: ClipItem, to board: Pinboard) {
        Task { await model.pin(item, to: board) }
    }

    func unpin(_ item: ClipItem) {
        Task { await model.unpin(item) }
    }

    func startCreatingBoard(pinning item: ClipItem? = nil) {
        boardEditor = BoardEditor(mode: .create(pinning: item), name: "")
    }

    func startRenaming(_ board: Pinboard) {
        boardEditor = BoardEditor(mode: .rename(board), name: board.name)
    }

    func commitBoardEditor() {
        guard let editor = boardEditor else { return }
        boardEditor = nil
        focusToken += 1
        let name = editor.name.trimmingCharacters(in: .whitespacesAndNewlines)
        switch editor.mode {
        case .create(let item):
            let finalName = !name.isEmpty ? name
                : pinboards.isEmpty ? ClipboardStore.defaultPinboardName : "Bảng \(pinboards.count + 1)"
            Task { await model.createPinboard(name: finalName, pinning: item) }
        case .rename(var board):
            guard !name.isEmpty, name != board.name else { return }
            board.name = name
            Task { await model.updatePinboard(board) }
        }
    }

    func cancelBoardEditor() {
        boardEditor = nil
        focusToken += 1
    }

    func setColor(_ hex: String, for board: Pinboard) {
        var board = board
        board.color = hex
        Task { await model.updatePinboard(board) }
    }

    func deleteBoard(_ board: Pinboard) {
        if filter == board.id.map(ClipFilter.pinboard) { filter = .all }
        Task { await model.deletePinboard(board) }
    }

    // MARK: - Sắp xếp trong Pinboard

    /// `⌘←` / `⌘→`: đổi chỗ thẻ đang chọn với thẻ bên cạnh.
    func moveSelectedPin(by delta: Int) {
        guard canReorder, let item = selectedItem else { return }
        let target = selectedIndex + delta
        guard items.indices.contains(target) else { return }
        selectedIndex = target
        Task { await model.movePin(item, to: target) }
    }

    var reorderTarget: Int? {
        guard let from = reorderIndex else { return nil }
        let to = from + Int((reorderTranslation / StripLayout.step).rounded())
        return min(max(to, 0), items.count - 1)
    }

    /// Độ lệch ngang của thẻ `index` khi đang kéo: thẻ được kéo theo chuột, các thẻ nằm giữa dịch sang nhường chỗ.
    func reorderOffset(for index: Int) -> CGFloat {
        guard let from = reorderIndex, let to = reorderTarget else { return 0 }
        if index == from { return reorderTranslation }
        if from < to, index > from, index <= to { return -StripLayout.step }
        if to < from, index >= to, index < from { return StripLayout.step }
        return 0
    }

    func reorderChanged(index: Int, translation: CGFloat) {
        if reorderIndex == nil {
            reorderIndex = index
            selectedIndex = index
        }
        withAnimation(.easeOut(duration: 0.12)) { reorderTranslation = translation }
    }

    func reorderEnded() {
        lastDragEnd = Date()
        guard let from = reorderIndex, let to = reorderTarget, items.indices.contains(from) else {
            reorderIndex = nil
            return
        }
        let item = items[from]
        guard to != from else {
            withAnimation(.easeOut(duration: 0.15)) { reorderTranslation = 0 }
            reorderIndex = nil
            return
        }
        Task {
            await model.movePin(item, to: to)
            // Giữ độ lệch tới khi thứ tự mới đã nạp xong, để thẻ không nhảy về chỗ cũ trong chốc lát.
            reorderIndex = nil
            reorderTranslation = 0
            selectedIndex = to
        }
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
        guard dragStartOffset == nil, reorderIndex == nil, Date().timeIntervalSince(lastDragEnd) > 0.2 else { return }
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

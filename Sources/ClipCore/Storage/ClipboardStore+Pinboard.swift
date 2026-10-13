import Foundation
import GRDB

/// Pinboard và ghim (DESIGN §4, PLAN M6). Mục đã ghim không bị retention xoá.
extension ClipboardStore {
    /// Màu gán lần lượt cho bảng mới.
    public static let pinboardPalette = [
        "#4F8EF7", "#F25C54", "#F7B32B", "#2BB673", "#9B5DE5", "#00B8D9", "#FF7AB6", "#8D99AE",
    ]

    public func pinboards() throws -> [Pinboard] {
        try database.queue.read { db in try Pinboard.order(Column("sort_order"), Column("id")).fetchAll(db) }
    }

    /// Tạo bảng ở cuối danh sách. Không truyền màu thì lấy màu kế tiếp trong bảng màu.
    @discardableResult
    public func createPinboard(name: String, color: String? = nil) throws -> Pinboard {
        try database.queue.write { db in
            let count = try Pinboard.fetchCount(db)
            let maxOrder = try Int.fetchOne(db, sql: "SELECT MAX(sort_order) FROM pinboard") ?? -1
            var board = Pinboard(
                name: name,
                color: color ?? Self.pinboardPalette[count % Self.pinboardPalette.count],
                sortOrder: maxOrder + 1)
            try board.insert(db)
            return board
        }
    }

    public func updatePinboard(_ board: Pinboard) throws {
        try database.queue.write { db in try board.update(db) }
    }

    /// Đặt lại thứ tự bảng theo `ids` (0…n-1). Bảng không có trong `ids` xếp sau, giữ thứ tự cũ.
    public func reorderPinboards(_ ids: [Int64]) throws {
        try database.queue.write { db in
            let all = try Int64.fetchAll(db, sql: "SELECT id FROM pinboard ORDER BY sort_order, id")
            let ordered = ids.filter(all.contains) + all.filter { !ids.contains($0) }
            for (order, id) in ordered.enumerated() {
                try db.execute(sql: "UPDATE pinboard SET sort_order = ? WHERE id = ?", arguments: [order, id])
            }
        }
    }

    /// Xoá bảng; các mục trong bảng được bỏ ghim (vẫn còn trong lịch sử), đưa lên đầu để không bị retention xoá ngay.
    public func deletePinboard(id: Int64, now: Date = Date()) throws {
        try database.queue.write { db in
            try db.execute(
                sql: "UPDATE clip_item SET pinboard_id = NULL, pin_order = NULL, last_used_at = ? WHERE pinboard_id = ?",
                arguments: [now.timeIntervalSince1970, id])
            _ = try Pinboard.deleteOne(db, key: id)
        }
    }

    /// Ghim vào cuối bảng. Đã ở đúng bảng đó thì giữ nguyên vị trí. Ghim cũng là giữ lại (bỏ hạn tự xoá).
    public func pin(itemID: Int64, to boardID: Int64) throws {
        try database.queue.write { db in
            let current = try Int64.fetchOne(db, sql: "SELECT pinboard_id FROM clip_item WHERE id = ?", arguments: [itemID])
            guard current != boardID else { return }
            let maxOrder = try Int.fetchOne(
                db, sql: "SELECT MAX(pin_order) FROM clip_item WHERE pinboard_id = ?", arguments: [boardID]) ?? -1
            try db.execute(
                sql: "UPDATE clip_item SET pinboard_id = ?, pin_order = ?, expires_at = NULL WHERE id = ?",
                arguments: [boardID, maxOrder + 1, itemID])
        }
    }

    /// Ghim nhanh vào bảng mặc định tên `boardName` (tên đã dịch, ví dụ "Đã ghim"); tạo bảng nếu chưa có,
    /// ví dụ người dùng đã đổi tên hoặc xoá nó.
    @discardableResult
    public func pinToDefault(itemID: Int64, boardName: String) throws -> Pinboard {
        let existing = try database.queue.read { db in
            try Pinboard.filter(Column("name") == boardName).order(Column("sort_order")).fetchOne(db)
        }
        let board = try existing ?? createPinboard(name: boardName)
        try pin(itemID: itemID, to: board.id!)
        return board
    }

    /// Bỏ ghim và đưa mục lên đầu lịch sử, để mục ghim lâu ngày không bị retention xoá ngay ở lần copy tiếp theo.
    public func unpin(itemID: Int64, now: Date = Date()) throws {
        try database.queue.write { db in
            try db.execute(
                sql: "UPDATE clip_item SET pinboard_id = NULL, pin_order = NULL, last_used_at = ? WHERE id = ?",
                arguments: [now.timeIntervalSince1970, itemID])
        }
    }

    /// Đưa mục tới vị trí `index` trong bảng của nó, đánh lại `pin_order` 0…n-1.
    public func movePin(itemID: Int64, to index: Int) throws {
        try database.queue.write { db in
            guard let boardID = try Int64.fetchOne(
                db, sql: "SELECT pinboard_id FROM clip_item WHERE id = ?", arguments: [itemID]) else { return }
            var ids = try Int64.fetchAll(
                db, sql: "SELECT id FROM clip_item WHERE pinboard_id = ? ORDER BY pin_order, id", arguments: [boardID])
            guard let from = ids.firstIndex(of: itemID) else { return }
            ids.remove(at: from)
            ids.insert(itemID, at: min(max(index, 0), ids.count))
            for (order, id) in ids.enumerated() {
                try db.execute(sql: "UPDATE clip_item SET pin_order = ? WHERE id = ?", arguments: [order, id])
            }
        }
    }
}

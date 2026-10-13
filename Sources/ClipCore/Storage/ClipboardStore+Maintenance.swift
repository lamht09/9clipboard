import Foundation
import GRDB

/// Xoá lịch sử hàng loạt. Mục đã ghim luôn được giữ.
extension ClipboardStore {
    /// Một app nguồn có mục trong lịch sử (chưa ghim).
    public struct SourceApp: Sendable, Hashable, Identifiable {
        public var bundleID: String
        public var name: String
        public var count: Int
        public var id: String { bundleID }
    }

    /// Các app nguồn có mục chưa ghim, nhiều mục nhất trước.
    public func sourceApps() throws -> [SourceApp] {
        try database.queue.read { db in
            try Row.fetchAll(db, sql: """
                SELECT source_bundle_id, MAX(source_app_name) AS name, COUNT(*) AS n
                FROM clip_item
                WHERE pinboard_id IS NULL AND source_bundle_id IS NOT NULL
                GROUP BY source_bundle_id
                ORDER BY n DESC, name
                """)
            .map { row in
                let bundleID: String = row["source_bundle_id"]
                return SourceApp(bundleID: bundleID, name: row["name"] ?? bundleID, count: row["n"])
            }
        }
    }

    /// Xoá mọi mục chưa ghim. Trả về số mục bị xoá.
    @discardableResult
    public func clearHistory() throws -> Int {
        try deleteUnpinned(ClipItem.filter(Column("pinboard_id") == nil))
    }

    /// Xoá mọi mục chưa ghim copy từ app `bundleID`. Trả về số mục bị xoá.
    @discardableResult
    public func clearHistory(fromApp bundleID: String) throws -> Int {
        try deleteUnpinned(ClipItem.filter(Column("pinboard_id") == nil && Column("source_bundle_id") == bundleID))
    }

    private func deleteUnpinned(_ request: QueryInterfaceRequest<ClipItem>) throws -> Int {
        let (count, blobPaths) = try database.queue.write { db -> (Int, [String]) in
            let ids = try request.select(Column("id"), as: Int64.self).fetchAll(db)
            guard !ids.isEmpty else { return (0, []) }
            let blobPaths = try Representation
                .filter(ids.contains(Column("item_id")) && Column("blob_path") != nil)
                .select(Column("blob_path"), as: String.self)
                .fetchAll(db)
            try ClipItem.filter(ids.contains(Column("id"))).deleteAll(db)
            return (ids.count, blobPaths)
        }
        blobs.delete(blobPaths: blobPaths)
        return count
    }
}

extension DataDirectory {
    /// Tổng dung lượng file trong `dir` (gồm cả thư mục con), tính theo byte.
    public static func diskUsage(of dir: URL) -> Int {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isRegularFileKey]
        guard let walker = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: keys) else { return 0 }
        var total = 0
        for case let url as URL in walker {
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else { continue }
            total += values.totalFileAllocatedSize ?? 0
        }
        return total
    }
}

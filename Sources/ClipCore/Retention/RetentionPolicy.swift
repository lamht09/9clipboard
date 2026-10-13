import GRDB

public enum RetentionPolicy {
    /// Xoá các mục chưa ghim cũ nhất khi số mục chưa ghim vượt `limit`.
    /// Trả về `blob_path` của các representation bị xoá để dọn file.
    @discardableResult
    static func prune(_ db: Database, limit: Int) throws -> [String] {
        let unpinned = ClipItem.filter(Column("pinboard_id") == nil)
        let count = try unpinned.fetchCount(db)
        guard count > limit else { return [] }

        let victims = try unpinned
            .order(Column("last_used_at").asc)
            .limit(count - limit)
            .select(Column("id"), as: Int64.self)
            .fetchAll(db)

        let blobPaths = try Representation
            .filter(victims.contains(Column("item_id")))
            .filter(Column("blob_path") != nil)
            .select(Column("blob_path"), as: String.self)
            .fetchAll(db)

        try ClipItem.filter(victims.contains(Column("id"))).deleteAll(db)
        return blobPaths
    }
}

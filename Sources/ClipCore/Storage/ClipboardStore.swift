import Foundation
import GRDB

public actor ClipboardStore {
    public enum InsertResult: Sendable, Equatable {
        case inserted(ClipItem)
        case bumped(ClipItem)

        public var item: ClipItem {
            switch self {
            case .inserted(let item), .bumped(let item): item
            }
        }
    }

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    /// Lưu lần copy mới. Nếu nội dung đã có thì chỉ đưa mục đó lên đầu.
    /// Sau đó áp dụng retention theo `historyLimit`.
    @discardableResult
    public func insertOrBump(_ capture: Capture, historyLimit: Int, now: Date = Date()) throws -> InsertResult {
        let hash = capture.contentHash
        return try database.queue.write { db in
            if var existing = try ClipItem.filter(Column("content_hash") == hash).fetchOne(db) {
                existing.lastUsedAt = now
                existing.sourceBundleID = capture.sourceBundleID ?? existing.sourceBundleID
                existing.sourceAppName = capture.sourceAppName ?? existing.sourceAppName
                try existing.update(db)
                return .bumped(existing)
            }

            var item = ClipItem(
                id: nil,
                kind: capture.kind,
                contentHash: hash,
                plainText: capture.plainText,
                searchKey: capture.plainText.map(TextNormalizer.normalize),
                sourceBundleID: capture.sourceBundleID,
                sourceAppName: capture.sourceAppName,
                byteSize: capture.byteSize,
                imageWidth: capture.imageWidth,
                imageHeight: capture.imageHeight,
                createdAt: now,
                lastUsedAt: now,
                useCount: 0,
                pinboardID: nil,
                pinOrder: nil
            )
            try item.insert(db)
            guard let id = item.id else { throw DatabaseError(message: "missing rowid") }
            for rep in capture.representations {
                try Representation(itemID: id, uti: rep.uti, data: rep.data).insert(db)
            }
            try RetentionPolicy.prune(db, limit: historyLimit)
            return .inserted(item)
        }
    }

    /// Các mục mới dùng nhất trước.
    public func recent(limit: Int = 2000) throws -> [ClipItem] {
        try database.queue.read { db in
            try ClipItem.order(Column("last_used_at").desc).limit(limit).fetchAll(db)
        }
    }

    public func item(id: Int64) throws -> ClipItem? {
        try database.queue.read { db in try ClipItem.fetchOne(db, key: id) }
    }

    public func representations(itemID: Int64) throws -> [Representation] {
        try database.queue.read { db in
            try Representation.filter(Column("item_id") == itemID).fetchAll(db)
        }
    }

    public func count() throws -> Int {
        try database.queue.read { db in try ClipItem.fetchCount(db) }
    }

    @discardableResult
    public func delete(id: Int64) throws -> [String] {
        try database.queue.write { db in
            let blobPaths = try Representation
                .filter(Column("item_id") == id && Column("blob_path") != nil)
                .select(Column("blob_path"), as: String.self)
                .fetchAll(db)
            _ = try ClipItem.deleteOne(db, key: id)
            return blobPaths
        }
    }

    /// Ghi nhận mục vừa được dán: đưa lên đầu và tăng số lần dùng.
    public func markUsed(id: Int64, now: Date = Date()) throws {
        try database.queue.write { db in
            try db.execute(
                sql: "UPDATE clip_item SET last_used_at = ?, use_count = use_count + 1 WHERE id = ?",
                arguments: [now.timeIntervalSince1970, id])
        }
    }

    @discardableResult
    public func applyRetention(limit: Int) throws -> [String] {
        try database.queue.write { db in try RetentionPolicy.prune(db, limit: limit) }
    }
}

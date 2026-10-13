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
    /// File ảnh; chỉ đọc nên dùng thẳng từ main thread được (ví dụ nạp thumbnail).
    public nonisolated let blobs: BlobStore

    public init(database: AppDatabase, blobs: BlobStore) {
        self.database = database
        self.blobs = blobs
    }

    /// Lưu lần copy mới. Nếu nội dung đã có thì chỉ đưa mục đó lên đầu.
    /// Ảnh được ghi ra `blobs/` (ném `BlobStore.Error.tooLarge` nếu vượt `maxImageBytes`) và tạo thumbnail.
    /// Sau đó áp dụng retention theo `historyLimit` và dọn file của các mục bị xoá.
    @discardableResult
    public func insertOrBump(
        _ capture: Capture,
        historyLimit: Int,
        maxImageBytes: Int = .max,
        now: Date = Date()
    ) throws -> InsertResult {
        let hash = capture.contentHash
        let (result, newBlobs, pruned) = try database.queue.write { db -> (InsertResult, [String], [String]) in
            if var existing = try ClipItem.filter(Column("content_hash") == hash).fetchOne(db) {
                existing.lastUsedAt = now
                existing.sourceBundleID = capture.sourceBundleID ?? existing.sourceBundleID
                existing.sourceAppName = capture.sourceAppName ?? existing.sourceAppName
                try existing.update(db)
                return (.bumped(existing), [], [])
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
            var newBlobs: [String] = []
            var storedBytes = 0
            for rep in capture.representations {
                if UTI.isImage(rep.uti) {
                    let path = try blobs.storeImage(rep.data, uti: rep.uti, name: hash, maxBytes: maxImageBytes)
                    newBlobs.append(path)
                    storedBytes += blobs.size(of: path)
                    try Representation(itemID: id, uti: UTI.png, blobPath: path).insert(db)
                } else {
                    storedBytes += rep.data.count
                    try Representation(itemID: id, uti: rep.uti, data: rep.data).insert(db)
                }
            }
            if storedBytes != item.byteSize {
                // TIFF đã đổi sang PNG: ghi kích thước thật trên đĩa.
                item.byteSize = storedBytes
                try item.update(db)
            }
            let pruned = try RetentionPolicy.prune(db, limit: historyLimit)
            return (.inserted(item), newBlobs, pruned)
        }

        blobs.delete(blobPaths: pruned)
        for path in newBlobs {
            do {
                try blobs.makeThumbnail(blobPath: path, name: hash)
            } catch {
                // Thiếu thumbnail thì thẻ hiện icon thay thế; không làm hỏng lần lưu.
            }
        }
        return result
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

    /// Xoá mục kèm file ảnh của nó.
    public func delete(id: Int64) throws {
        let blobPaths = try database.queue.write { db in
            let blobPaths = try Representation
                .filter(Column("item_id") == id && Column("blob_path") != nil)
                .select(Column("blob_path"), as: String.self)
                .fetchAll(db)
            _ = try ClipItem.deleteOne(db, key: id)
            return blobPaths
        }
        blobs.delete(blobPaths: blobPaths)
    }

    /// Ghi nhận mục vừa được dán: đưa lên đầu và tăng số lần dùng.
    public func markUsed(id: Int64, now: Date = Date()) throws {
        try database.queue.write { db in
            try db.execute(
                sql: "UPDATE clip_item SET last_used_at = ?, use_count = use_count + 1 WHERE id = ?",
                arguments: [now.timeIntervalSince1970, id])
        }
    }

    public func applyRetention(limit: Int) throws {
        let blobPaths = try database.queue.write { db in try RetentionPolicy.prune(db, limit: limit) }
        blobs.delete(blobPaths: blobPaths)
    }
}

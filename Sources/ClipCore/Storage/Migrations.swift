import GRDB

enum Migrations {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "pinboard") { t in
                t.primaryKey("id", .integer)
                t.column("name", .text).notNull()
                t.column("color", .text).notNull()
                t.column("sort_order", .integer).notNull()
            }

            try db.create(table: "clip_item") { t in
                t.primaryKey("id", .integer)
                t.column("kind", .text).notNull()
                t.column("content_hash", .text).notNull().unique()
                t.column("plain_text", .text)
                t.column("search_key", .text)
                t.column("source_bundle_id", .text)
                t.column("source_app_name", .text)
                t.column("byte_size", .integer).notNull()
                t.column("image_width", .integer)
                t.column("image_height", .integer)
                t.column("created_at", .double).notNull()
                t.column("last_used_at", .double).notNull()
                t.column("use_count", .integer).notNull().defaults(to: 0)
                t.column("pinboard_id", .integer).references("pinboard", onDelete: .setNull)
                t.column("pin_order", .integer)
            }
            try db.create(index: "idx_clip_last_used", on: "clip_item", columns: ["last_used_at"])
            try db.create(index: "idx_clip_pinboard", on: "clip_item", columns: ["pinboard_id", "pin_order"])

            try db.create(table: "representation") { t in
                t.column("item_id", .integer).notNull().references("clip_item", onDelete: .cascade)
                t.column("uti", .text).notNull()
                t.column("data", .blob)
                t.column("blob_path", .text)
                t.primaryKey(["item_id", "uti"])
            }
        }

        // Mục nhạy cảm tự xoá sau một khoảng thời gian.
        migrator.registerMigration("v2") { db in
            try db.alter(table: "clip_item") { t in
                t.add(column: "expires_at", .double)
            }
            try db.create(index: "idx_clip_expires", on: "clip_item", columns: ["expires_at"])
        }

        // Tìm theo cách đọc (pinyin, romaji, phụ âm đầu Hangul) và chuẩn hoá thêm ß, œ, kana…
        migrator.registerMigration("v3") { db in
            try db.alter(table: "clip_item") { t in
                t.add(column: "phonetic_key", .text)
            }
            try rebuildSearchKeys(db)
        }

        return migrator
    }

    /// Tính lại khoá tìm kiếm của mọi mục. Gọi lại trong một migration mới mỗi khi đổi
    /// `TextNormalizer` hay `PhoneticKey`, để lịch sử cũ tìm được theo cách mới.
    static func rebuildSearchKeys(_ db: Database) throws {
        let rows = try Row.fetchAll(db, sql: "SELECT id, plain_text FROM clip_item WHERE plain_text IS NOT NULL")
        let update = try db.makeStatement(sql: "UPDATE clip_item SET search_key = ?, phonetic_key = ? WHERE id = ?")
        for row in rows {
            let id: Int64 = row["id"]
            let text: String = row["plain_text"]
            try update.execute(arguments: [TextNormalizer.normalize(text), PhoneticKey.make(text), id])
        }
    }
}

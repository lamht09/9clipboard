import Foundation
import GRDB
import Testing
@testable import ClipCore

@Suite struct ClipboardStoreTests {
    @Test func insertsAndOrdersByLastUsed() async throws {
        let (store, _) = try makeStore()
        let t0 = Date(timeIntervalSince1970: 1000)
        try await store.insertOrBump(textCapture("a"), historyLimit: 500, now: t0)
        try await store.insertOrBump(textCapture("b"), historyLimit: 500, now: t0 + 1)
        try await store.insertOrBump(textCapture("c"), historyLimit: 500, now: t0 + 2)
        let items = try await store.recent()
        #expect(items.map(\.plainText) == ["c", "b", "a"])
    }

    @Test func duplicateBumpsInsteadOfInserting() async throws {
        let (store, _) = try makeStore()
        let t0 = Date(timeIntervalSince1970: 1000)
        let first = try await store.insertOrBump(textCapture("a", app: "com.a"), historyLimit: 500, now: t0)
        try await store.insertOrBump(textCapture("b"), historyLimit: 500, now: t0 + 1)
        let again = try await store.insertOrBump(textCapture("a", app: "com.z"), historyLimit: 500, now: t0 + 2)

        guard case .bumped(let bumped) = again else { Issue.record("expected bump"); return }
        #expect(bumped.id == first.item.id)
        #expect(bumped.sourceBundleID == "com.z")
        #expect(try await store.count() == 2)
        #expect(try await store.recent().first?.plainText == "a")
    }

    @Test func storesRepresentationsAndSearchKey() async throws {
        let (store, _) = try makeStore()
        let item = try await store.insertOrBump(textCapture("Báo Cáo  Đà Nẵng"), historyLimit: 500).item
        #expect(item.searchKey == "bao cao da nang")
        #expect(item.phoneticKey == nil)
        let reps = try await store.representations(itemID: item.id!)
        #expect(reps.map(\.uti) == [UTI.plainText])
    }

    @Test func retentionDropsOldestUnpinnedButKeepsPinned() async throws {
        let (store, db) = try makeStore()
        let t0 = Date(timeIntervalSince1970: 1000)
        let oldest = try await store.insertOrBump(textCapture("pinned"), historyLimit: 3, now: t0).item

        // Ghim mục cũ nhất
        try await db.queue.write { db in
            var board = Pinboard(name: "Đã ghim", color: "#4F8EF7", sortOrder: 0)
            try board.insert(db)
            try db.execute(sql: "UPDATE clip_item SET pinboard_id = ? WHERE id = ?", arguments: [board.id, oldest.id])
        }

        for i in 1...5 {
            try await store.insertOrBump(textCapture("item \(i)"), historyLimit: 3, now: t0 + Double(i))
        }
        let texts = try await store.recent().compactMap(\.plainText)
        #expect(texts == ["item 5", "item 4", "item 3", "pinned"])
    }

    @Test func markUsedBumpsAndCounts() async throws {
        let (store, _) = try makeStore()
        let t0 = Date(timeIntervalSince1970: 1000)
        let a = try await store.insertOrBump(textCapture("a"), historyLimit: 500, now: t0).item
        try await store.insertOrBump(textCapture("b"), historyLimit: 500, now: t0 + 1)
        try await store.markUsed(id: a.id!, now: t0 + 2)
        let items = try await store.recent()
        #expect(items.first?.plainText == "a")
        #expect(items.first?.useCount == 1)
    }

    @Test func deleteRemovesItemAndRepresentations() async throws {
        let (store, db) = try makeStore()
        let a = try await store.insertOrBump(textCapture("a"), historyLimit: 500).item
        try await store.delete(id: a.id!)
        #expect(try await store.count() == 0)
        let reps = try await db.queue.read { try Representation.fetchCount($0) }
        #expect(reps == 0)
    }
}

@Test func datesAreStoredAsReal() async throws {
    let (store, db) = try makeStore()
    try await store.insertOrBump(textCapture("a"), historyLimit: 500)
    let types = try await db.queue.read {
        try String.fetchAll($0, sql: "SELECT typeof(created_at) || typeof(last_used_at) FROM clip_item")
    }
    #expect(types == ["realreal"])
}

@Suite struct SearchKeyMigrationTests {
    @Test func v3RebuildsKeysOfOldItems() throws {
        let queue = try DatabaseQueue()
        try Migrations.migrator.migrate(queue, upTo: "v2")
        try queue.write { db in
            // Khoá cũ kiểu v2: chưa đổi ß, chưa có cách đọc.
            try db.execute(sql: """
                INSERT INTO clip_item (kind, content_hash, plain_text, search_key, byte_size, created_at, last_used_at)
                VALUES ('text', 'a', 'Straße', 'straße', 7, 0, 0), ('text', 'b', '北京', '北京', 6, 0, 0),
                       ('image', 'c', NULL, NULL, 100, 0, 0)
                """)
        }
        try Migrations.migrator.migrate(queue)
        let items = try queue.read { db in try ClipItem.order(Column("content_hash")).fetchAll(db) }
        #expect(items.map(\.searchKey) == ["strasse", "北京", nil])
        #expect(items[0].phoneticKey == nil)
        #expect(items[1].phoneticKey?.contains("beijing") == true)
        #expect(items[2].phoneticKey == nil)
    }
}

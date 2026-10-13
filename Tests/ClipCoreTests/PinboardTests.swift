import Foundation
import Testing
@testable import ClipCore

@Suite struct PinboardTests {
    private let t0 = Date(timeIntervalSince1970: 1000)

    @Test func createsBoardsInOrderWithPaletteColors() async throws {
        let (store, _) = try makeStore()
        let a = try await store.createPinboard(name: "Code")
        let b = try await store.createPinboard(name: "Công việc")
        #expect(try await store.pinboards().map(\.name) == ["Code", "Công việc"])
        #expect(a.color == ClipboardStore.pinboardPalette[0])
        #expect(b.color == ClipboardStore.pinboardPalette[1])
        #expect(b.sortOrder > a.sortOrder)
    }

    @Test func pinAppendsAndMoveReorders() async throws {
        let (store, _) = try makeStore()
        let board = try await store.createPinboard(name: "Code")
        var ids: [Int64] = []
        for (i, text) in ["a", "b", "c"].enumerated() {
            let item = try await store.insertOrBump(textCapture(text), historyLimit: 500, now: t0 + Double(i)).item
            try await store.pin(itemID: item.id!, to: board.id!)
            ids.append(item.id!)
        }
        func order() async throws -> [String] {
            SearchEngine().search(try await store.recent(), query: "", filter: .pinboard(board.id!))
                .compactMap(\.item.plainText)
        }
        #expect(try await order() == ["a", "b", "c"])

        try await store.movePin(itemID: ids[2], to: 0)
        #expect(try await order() == ["c", "a", "b"])
        try await store.movePin(itemID: ids[2], to: 99)
        #expect(try await order() == ["a", "b", "c"])

        // Ghim lại vào cùng bảng thì giữ nguyên vị trí.
        try await store.pin(itemID: ids[0], to: board.id!)
        #expect(try await order() == ["a", "b", "c"])
    }

    @Test func pinnedItemsSurviveRetention() async throws {
        let (store, _) = try makeStore()
        let board = try await store.createPinboard(name: "Code")
        for i in 0..<3 {
            let item = try await store.insertOrBump(textCapture("pin \(i)"), historyLimit: 500, now: t0 + Double(i)).item
            try await store.pin(itemID: item.id!, to: board.id!)
        }
        for i in 0..<600 {
            try await store.insertOrBump(textCapture("x \(i)"), historyLimit: 500, now: t0 + 10 + Double(i))
        }
        let items = try await store.recent(limit: 2000)
        #expect(items.count == 503)
        #expect(items.filter { $0.pinboardID == board.id }.count == 3)
    }

    @Test func recentIncludesOldPinnedBeyondLimit() async throws {
        let (store, _) = try makeStore()
        let board = try await store.createPinboard(name: "Code")
        let old = try await store.insertOrBump(textCapture("old"), historyLimit: 500, now: t0).item
        try await store.pin(itemID: old.id!, to: board.id!)
        for i in 1...5 {
            try await store.insertOrBump(textCapture("new \(i)"), historyLimit: 500, now: t0 + Double(i))
        }
        let items = try await store.recent(limit: 3)
        #expect(items.compactMap(\.plainText) == ["new 5", "new 4", "new 3", "old"])
    }

    @Test func unpinBumpsToTopSoRetentionKeepsIt() async throws {
        let (store, _) = try makeStore()
        let board = try await store.createPinboard(name: "Code")
        let old = try await store.insertOrBump(textCapture("old"), historyLimit: 2, now: t0).item
        try await store.pin(itemID: old.id!, to: board.id!)
        for i in 1...3 {
            try await store.insertOrBump(textCapture("n \(i)"), historyLimit: 2, now: t0 + Double(i))
        }
        try await store.unpin(itemID: old.id!, now: t0 + 10)
        try await store.insertOrBump(textCapture("n 4"), historyLimit: 2, now: t0 + 11)
        let items = try await store.recent()
        #expect(items.compactMap(\.plainText) == ["n 4", "old"])
        #expect(items.allSatisfy { $0.pinboardID == nil && $0.pinOrder == nil })
    }

    @Test func pinToDefaultCreatesBoardOnceAndMovesBetweenBoards() async throws {
        let (store, _) = try makeStore()
        let code = try await store.createPinboard(name: "Code")
        let a = try await store.insertOrBump(textCapture("a"), historyLimit: 500, now: t0).item
        let b = try await store.insertOrBump(textCapture("b"), historyLimit: 500, now: t0 + 1).item
        let first = try await store.pinToDefault(itemID: a.id!)
        let second = try await store.pinToDefault(itemID: b.id!)
        #expect(first.id == second.id)
        #expect(try await store.pinboards().map(\.name) == ["Code", ClipboardStore.defaultPinboardName])

        // Chuyển sang bảng khác: thêm vào cuối bảng đích.
        try await store.pin(itemID: b.id!, to: code.id!)
        let moved = try #require(try await store.item(id: b.id!))
        #expect(moved.pinboardID == code.id)
        #expect(moved.pinOrder == 0)
    }

    @Test func deletingBoardUnpinsItsItems() async throws {
        let (store, _) = try makeStore()
        let board = try await store.createPinboard(name: "Code")
        let item = try await store.insertOrBump(textCapture("a"), historyLimit: 500, now: t0).item
        try await store.pin(itemID: item.id!, to: board.id!)
        try await store.deletePinboard(id: board.id!)
        #expect(try await store.pinboards().isEmpty)
        let after = try #require(try await store.item(id: item.id!))
        #expect(after.pinboardID == nil)
        #expect(after.pinOrder == nil)
    }
}

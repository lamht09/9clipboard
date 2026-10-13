import Foundation
import Testing
@testable import ClipCore

@Suite struct MaintenanceTests {
    private let t0 = Date(timeIntervalSince1970: 1000)

    @Test func clearHistoryKeepsPinnedAndRemovesBlobs() async throws {
        let (store, _) = try makeStore()
        let board = try await store.createPinboard(name: "Code")
        let pinned = try await store.insertOrBump(textCapture("giữ"), historyLimit: 500, now: t0).item
        try await store.pin(itemID: pinned.id!, to: board.id!)
        try await store.insertOrBump(textCapture("a"), historyLimit: 500, now: t0 + 1)
        let image = try await store.insertOrBump(imageCapture(makeImage()), historyLimit: 500, now: t0 + 2).item
        let blobPath = try await store.representations(itemID: image.id!).compactMap(\.blobPath).first!
        #expect(FileManager.default.fileExists(atPath: store.blobs.url(forBlob: blobPath).path))

        #expect(try await store.clearHistory() == 2)
        #expect(try await store.recent().map(\.plainText) == ["giữ"])
        #expect(!FileManager.default.fileExists(atPath: store.blobs.url(forBlob: blobPath).path))
    }

    @Test func clearHistoryFromOneApp() async throws {
        let (store, _) = try makeStore()
        let board = try await store.createPinboard(name: "Code")
        try await store.insertOrBump(textCapture("s1", app: "com.slack"), historyLimit: 500, now: t0)
        try await store.insertOrBump(textCapture("s2", app: "com.slack"), historyLimit: 500, now: t0 + 1)
        let pinned = try await store.insertOrBump(textCapture("s3", app: "com.slack"), historyLimit: 500, now: t0 + 2).item
        try await store.pin(itemID: pinned.id!, to: board.id!)
        try await store.insertOrBump(textCapture("v1", app: "com.vscode"), historyLimit: 500, now: t0 + 3)
        try await store.insertOrBump(textCapture("x"), historyLimit: 500, now: t0 + 4)

        #expect(try await store.sourceApps().map { [$0.bundleID: $0.count] } == [["com.slack": 2], ["com.vscode": 1]])

        #expect(try await store.clearHistory(fromApp: "com.slack") == 2)
        #expect(Set(try await store.recent().compactMap(\.plainText)) == ["s3", "v1", "x"])
        #expect(try await store.sourceApps().map(\.bundleID) == ["com.vscode"])
    }

    @Test func reorderPinboards() async throws {
        let (store, _) = try makeStore()
        let a = try await store.createPinboard(name: "A")
        try await store.createPinboard(name: "B")
        let c = try await store.createPinboard(name: "C")
        try await store.reorderPinboards([c.id!, a.id!])
        #expect(try await store.pinboards().map(\.name) == ["C", "A", "B"])
    }

    @Test func diskUsageCountsNestedFiles() throws {
        let blobs = try makeBlobStore()
        _ = try blobs.storeImage(makeImage(), uti: UTI.png, name: "abcdef")
        #expect(DataDirectory.diskUsage(of: blobs.root) > 0)
    }
}

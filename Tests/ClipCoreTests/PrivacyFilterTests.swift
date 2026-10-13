import Foundation
import Testing
@testable import ClipCore

@Suite struct PrivacyFilterTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func recordsOrdinaryCopy() {
        let pb = FakePasteboard.text("xin chào")
        #expect(PrivacyFilter().evaluate(types: pb.typeIdentifiers, sourceBundleID: "com.apple.TextEdit", now: now) == .record)
    }

    @Test(arguments: PrivacyFilter.concealedTypes)
    func concealedTypesAreRecordedAsSensitive(type: String) {
        let pb = FakePasteboard.text("hunter2", extra: [type: Data()])
        let decision = PrivacyFilter().evaluate(types: pb.typeIdentifiers, sourceBundleID: "com.google.Chrome", now: now)
        #expect(decision == .recordSensitive(type))
        #expect(decision.shouldRecord)
    }

    @Test(arguments: PrivacyFilter.transientTypes)
    func transientTypesAreIgnored(type: String) {
        let pb = FakePasteboard.text("tạm", extra: [type: Data()])
        let decision = PrivacyFilter().evaluate(types: pb.typeIdentifiers, sourceBundleID: nil, now: now)
        #expect(decision == .transient(type))
        #expect(!decision.shouldRecord)
    }

    @Test func passwordManagersAreSensitive() {
        for id in ["com.1password.1password", "com.bitwarden.desktop", "com.apple.keychainaccess", "com.apple.Passwords"] {
            #expect(PrivacyFilter().evaluate(types: [UTI.plainText], sourceBundleID: id, now: now) == .recordSensitive(id))
        }
    }

    @Test func passwordDetectionCanBeTurnedOff() {
        let filter = PrivacyFilter(detectPasswords: false)
        #expect(filter.evaluate(types: [UTI.plainText, "org.nspasteboard.ConcealedType"], sourceBundleID: nil, now: now) == .record)
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: "com.bitwarden.desktop", now: now) == .record)
    }

    @Test func excludedAppsAreIgnored() {
        let filter = PrivacyFilter(excludedBundleIDs: ["com.tinyspeck.slackmacgap"])
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: "com.tinyspeck.slackmacgap", now: now) == .excludedApp("com.tinyspeck.slackmacgap"))
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: "com.apple.TextEdit", now: now) == .record)
    }

    @Test func pauseExpires() {
        let filter = PrivacyFilter(pausedUntil: now.addingTimeInterval(15 * 60))
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: nil, now: now) == .paused)
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: nil, now: now.addingTimeInterval(15 * 60 - 1)) == .paused)
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: nil, now: now.addingTimeInterval(15 * 60)) == .record)
    }

    @Test func pauseIndefinitely() {
        let filter = PrivacyFilter(pausedUntil: .distantFuture)
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: nil, now: now.addingTimeInterval(1e9)) == .paused)
    }

    @Test func skipNextOnlyWhenOtherwiseRecorded() {
        let filter = PrivacyFilter(excludedBundleIDs: ["com.tinyspeck.slackmacgap"], skipNext: true)
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: nil, now: now) == .skippedOnce)
        #expect(filter.evaluate(types: [UTI.plainText, "org.nspasteboard.ConcealedType"], sourceBundleID: nil, now: now) == .skippedOnce)
        // Copy bị chặn vì lý do khác không tiêu mất lượt bỏ qua.
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: "com.tinyspeck.slackmacgap", now: now) == .excludedApp("com.tinyspeck.slackmacgap"))
    }
}

@Suite struct ExpiringItemTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func expiredItemsArePurged() async throws {
        let (store, _) = try makeStore()
        try await store.insertOrBump(textCapture("hunter2"), historyLimit: 500, expiresAt: now.addingTimeInterval(900), now: now)
        try await store.insertOrBump(textCapture("bình thường"), historyLimit: 500, now: now)

        #expect(try await store.purgeExpired(now: now.addingTimeInterval(899)) == 0)
        #expect(try await store.count() == 2)
        #expect(try await store.purgeExpired(now: now.addingTimeInterval(900)) == 1)
        #expect(try await store.recent().map(\.plainText) == ["bình thường"])
    }

    @Test func keepRemovesExpiry() async throws {
        let (store, _) = try makeStore()
        let item = try await store.insertOrBump(textCapture("hunter2"), historyLimit: 500, expiresAt: now.addingTimeInterval(900), now: now).item
        #expect(item.isExpiring)
        try await store.keep(itemID: item.id!)
        #expect(try await store.purgeExpired(now: now.addingTimeInterval(3600)) == 0)
        #expect(try await store.item(id: item.id!)?.expiresAt == nil)
    }

    @Test func pinningKeepsItem() async throws {
        let (store, _) = try makeStore()
        let item = try await store.insertOrBump(textCapture("hunter2"), historyLimit: 500, expiresAt: now.addingTimeInterval(900), now: now).item
        try await store.pinToDefault(itemID: item.id!, boardName: "Pinned")
        #expect(try await store.purgeExpired(now: now.addingTimeInterval(3600)) == 0)
        #expect(try await store.item(id: item.id!)?.isPinned == true)
    }

    @Test func recopyExtendsExpiryButNeverAddsOne() async throws {
        let (store, _) = try makeStore()
        let secret = try await store.insertOrBump(textCapture("hunter2"), historyLimit: 500, expiresAt: now.addingTimeInterval(900), now: now).item
        try await store.insertOrBump(textCapture("hunter2"), historyLimit: 500, expiresAt: now.addingTimeInterval(1500), now: now.addingTimeInterval(600))
        #expect(try await store.item(id: secret.id!)?.expiresAt == now.addingTimeInterval(1500))

        // Mục đã có sẵn (hoặc đã giữ lại) thì copy lại dạng mật khẩu không gắn hạn tự xoá.
        let kept = try await store.insertOrBump(textCapture("token cũ"), historyLimit: 500, now: now).item
        try await store.insertOrBump(textCapture("token cũ"), historyLimit: 500, expiresAt: now.addingTimeInterval(900), now: now)
        #expect(try await store.item(id: kept.id!)?.expiresAt == nil)
    }
}

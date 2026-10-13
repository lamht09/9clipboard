import Foundation
import Testing
@testable import ClipCore

@Suite struct PrivacyFilterTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func types(_ pb: FakePasteboard) -> [String] { pb.typeIdentifiers }

    @Test func recordsOrdinaryCopy() {
        let pb = FakePasteboard.text("xin chào")
        #expect(PrivacyFilter().evaluate(types: types(pb), sourceBundleID: "com.apple.TextEdit", now: now) == .record)
    }

    @Test(arguments: PrivacyFilter.sensitiveTypes)
    func ignoresSensitiveTypes(type: String) {
        let pb = FakePasteboard.text("hunter2", extra: [type: Data()])
        #expect(PrivacyFilter().evaluate(types: types(pb), sourceBundleID: "com.google.Chrome", now: now) == .sensitive(type))
    }

    @Test func sensitiveTypesCanBeAllowed() {
        let pb = FakePasteboard.text("hunter2", extra: ["org.nspasteboard.ConcealedType": Data()])
        let filter = PrivacyFilter(ignoreSensitiveTypes: false)
        #expect(filter.evaluate(types: types(pb), sourceBundleID: nil, now: now) == .record)
    }

    @Test func excludesDefaultPasswordManagers() {
        let pb = FakePasteboard.text("hunter2")
        for id in ["com.1password.1password", "com.bitwarden.desktop", "com.apple.keychainaccess", "com.apple.Passwords"] {
            #expect(PrivacyFilter().evaluate(types: types(pb), sourceBundleID: id, now: now) == .excludedApp(id))
        }
        let custom = PrivacyFilter(excludedBundleIDs: ["com.tinyspeck.slackmacgap"])
        #expect(custom.evaluate(types: types(pb), sourceBundleID: "com.tinyspeck.slackmacgap", now: now) == .excludedApp("com.tinyspeck.slackmacgap"))
        #expect(custom.evaluate(types: types(pb), sourceBundleID: "com.1password.1password", now: now) == .record)
    }

    @Test func pauseExpires() {
        let pb = FakePasteboard.text("a")
        let filter = PrivacyFilter(pausedUntil: now.addingTimeInterval(15 * 60))
        #expect(filter.evaluate(types: types(pb), sourceBundleID: nil, now: now) == .paused)
        #expect(filter.evaluate(types: types(pb), sourceBundleID: nil, now: now.addingTimeInterval(15 * 60 - 1)) == .paused)
        #expect(filter.evaluate(types: types(pb), sourceBundleID: nil, now: now.addingTimeInterval(15 * 60)) == .record)
    }

    @Test func pauseIndefinitely() {
        let filter = PrivacyFilter(pausedUntil: .distantFuture)
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: nil, now: now.addingTimeInterval(1e9)) == .paused)
    }

    @Test func skipNextOnlyWhenOtherwiseRecorded() {
        let filter = PrivacyFilter(skipNext: true)
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: nil, now: now) == .skippedOnce)
        // Copy từ app loại trừ không tiêu mất lượt bỏ qua.
        #expect(filter.evaluate(types: [UTI.plainText], sourceBundleID: "com.bitwarden.desktop", now: now) == .excludedApp("com.bitwarden.desktop"))
    }
}

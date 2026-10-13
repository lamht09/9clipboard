import ClipCore
import Foundation

/// Trạng thái tạm dừng / bỏ qua lần copy tiếp theo, và lọc mỗi lần copy qua `PrivacyFilter`.
@MainActor
final class PrivacyController {
    /// Gọi khi trạng thái đổi (bắt đầu/hết tạm dừng, bật/tắt bỏ qua) để menu bar cập nhật icon.
    var onChange: () -> Void = {}
    private(set) var skipNext = false
    private var resumeTimer: Timer?

    init() {
        // Lần tạm dừng đã hết hạn khi app không chạy thì xoá luôn.
        if let until = Preferences.pausedUntil, until <= Date() { Preferences.pausedUntil = nil }
        scheduleResume()
    }

    var pausedUntil: Date? {
        guard let until = Preferences.pausedUntil, until > Date() else { return nil }
        return until
    }

    var isPaused: Bool { pausedUntil != nil }

    /// `nil` = tạm dừng đến khi bật lại.
    func pause(for duration: TimeInterval?) {
        Preferences.pausedUntil = duration.map { Date().addingTimeInterval($0) } ?? .distantFuture
        scheduleResume()
        onChange()
    }

    func resume() {
        Preferences.pausedUntil = nil
        scheduleResume()
        onChange()
    }

    func toggleSkipNext() {
        skipNext.toggle()
        onChange()
    }

    /// Quyết định cho lần copy này. Tiêu lượt "bỏ qua lần tiếp theo" nếu có.
    func evaluate(types: [String], sourceBundleID: String?) -> PrivacyFilter.Decision {
        let filter = PrivacyFilter(
            detectPasswords: Preferences.detectPasswords,
            excludedBundleIDs: Set(Preferences.excludedBundleIDs),
            pausedUntil: pausedUntil,
            skipNext: skipNext)
        let decision = filter.evaluate(types: types, sourceBundleID: sourceBundleID)
        if decision == .skippedOnce {
            skipNext = false
            onChange()
        }
        if decision != .record {
            log.debug("lần copy: \(String(describing: decision))")
        }
        return decision
    }

    /// Hẹn giờ tự bật lại, để icon đổi về đúng lúc kể cả khi không có lần copy nào.
    private func scheduleResume() {
        resumeTimer?.invalidate()
        resumeTimer = nil
        guard let until = pausedUntil, until != .distantFuture else { return }
        let timer = Timer(fire: until, interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                Preferences.pausedUntil = nil
                self?.onChange()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        resumeTimer = timer
    }
}

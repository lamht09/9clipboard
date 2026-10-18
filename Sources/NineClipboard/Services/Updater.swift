import AppKit
import ClipCore
import Observation

/// Kiểm tra và cài bản cập nhật từ GitHub Releases. Không có thông báo bật lên: kết quả chỉ hiện ở
/// Settings › Cập nhật. Chỉ hỏi số phiên bản mới nhất, không gửi gì về người dùng hay clipboard.
@MainActor
@Observable
final class Updater {
    enum Phase: Equatable {
        case idle
        case checking
        case downloading
        case installing
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    /// Bản mới nhất tìm được ở lần kiểm tra gần nhất; `nil` là đang dùng bản mới nhất (hoặc chưa kiểm tra).
    private(set) var update: AvailableUpdate?
    private(set) var lastChecked = Preferences.lastUpdateCheck
    /// Đã kiểm tra thành công trong lần chạy này. Kết quả không lưu qua lần khởi động sau,
    /// nên chưa kiểm tra thì không được hiện "đang là bản mới nhất".
    private(set) var hasResult = false
    /// Phiên bản tự cài đã lỗi: không tự thử lại mỗi giờ (vẫn bấm "Cập nhật ngay" được).
    private var failedAutoInstall: SemanticVersion?

    let currentVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String).flatMap(SemanticVersion.init)

    /// Panel đang mở thì tự cài phải đợi, không khởi động lại giữa lúc người dùng đang chọn.
    var isPanelShown: () -> Bool = { false }

    private static let feedURL = URL(string: "https://api.github.com/repos/lamht09/9clipboard/releases?per_page=30")!

    /// Ghi đè nguồn bản phát hành để thử (có thể là file://): `defaults write <bundle id> updateFeedURL <url>`.
    /// Không phải lỗ hổng: bản tải về vẫn phải ký đúng chứng chỉ của app đang chạy.
    private static var feedOverride: URL? {
        UserDefaults.standard.string(forKey: "updateFeedURL").flatMap(URL.init(string:))
    }

    /// Bản dev không tự cập nhật (trừ khi đặt `updateFeedURL` để thử).
    var isSupported: Bool {
        currentVersion != nil && (!isDevBuild || Self.feedOverride != nil)
    }

    var isBusy: Bool {
        switch phase {
        case .checking, .downloading, .installing: true
        case .idle, .failed: false
        }
    }

    // MARK: - Kiểm tra

    /// Kiểm tra định kỳ (mỗi ngày một lần) khi bật tự kiểm tra.
    func start() {
        guard isSupported else { return }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(60))
            while let self {
                self.backgroundTick()
                try? await Task.sleep(for: .seconds(60 * 60))
            }
        }
    }

    /// Mỗi giờ: kiểm tra nếu đã quá một ngày; đã biết có bản mới (ví dụ tìm thấy lúc mở Settings) và
    /// bật tự cài thì cài luôn.
    private func backgroundTick() {
        if let update, update.version != failedAutoInstall,
           Preferences.autoCheckUpdates, Preferences.autoInstallUpdates, !isBusy {
            Task { await install(update, automatic: true) }
        } else {
            checkIfDue(after: 24 * 60 * 60, needsResult: false)
        }
    }

    /// Mở Settings: kiểm tra nếu lần chạy này chưa có kết quả hoặc kết quả đã quá một giờ.
    func settingsOpened() {
        checkIfDue(after: 60 * 60, needsResult: true)
    }

    /// `needsResult`: Settings cần kết quả để hiển thị, nên chưa có kết quả trong lần chạy này thì kiểm tra luôn.
    private func checkIfDue(after interval: TimeInterval, needsResult: Bool) {
        guard isSupported, Preferences.autoCheckUpdates, !isBusy else { return }
        let recent = lastChecked.map { Date().timeIntervalSince($0) < interval } ?? false
        if recent && (hasResult || !needsResult) { return }
        // Chỉ lần kiểm tra nền mới tự cài; đang mở Settings thì không tự khởi động lại.
        Task { await check(autoInstall: !needsResult) }
    }

    func checkNow() {
        Task { await check(autoInstall: false) }
    }

    /// Đổi kênh beta: kết quả cũ không còn đúng, kiểm tra lại ngay (không tự cài).
    func channelChanged() {
        guard isSupported, !isBusy else { return }
        update = nil
        hasResult = false
        checkNow()
    }

    private func check(autoInstall: Bool) async {
        guard isSupported, !isBusy, let currentVersion else { return }
        phase = .checking
        do {
            var request = URLRequest(url: Self.feedOverride ?? Self.feedURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw UpdateInstaller.Failure.download(http.statusCode)
            }
            update = ReleaseFeed.newestUpdate(
                in: try ReleaseFeed.decode(data), current: currentVersion,
                includePrerelease: Preferences.includeBetaUpdates)
            lastChecked = Date()
            Preferences.lastUpdateCheck = lastChecked
            hasResult = true
            phase = .idle
        } catch {
            log.error("Kiểm tra cập nhật lỗi: \(error.localizedDescription)")
            phase = .failed(String(localized: "Couldn’t check for updates: \(error.localizedDescription)"))
            return
        }
        if let update, autoInstall, update.version != failedAutoInstall, Preferences.autoInstallUpdates {
            await install(update, automatic: true)
        }
    }

    // MARK: - Cài đặt

    func installNow() {
        guard let update, !isBusy else { return }
        Task { await install(update, automatic: false) }
    }

    private func install(_ update: AvailableUpdate, automatic: Bool) async {
        let appURL = Bundle.main.bundleURL.resolvingSymlinksInPath()
        phase = .downloading
        let staged: UpdateInstaller.Staged
        do {
            staged = try await Task.detached { try await UpdateInstaller.download(update, replacing: appURL) }.value
        } catch {
            log.error("Tải bản cập nhật lỗi: \(error.localizedDescription)")
            if automatic { failedAutoInstall = update.version }
            phase = .failed(String(localized: "Couldn’t install the update: \(error.localizedDescription)"))
            return
        }
        while automatic, isPanelShown() {
            try? await Task.sleep(for: .seconds(30))
        }
        phase = .installing
        do {
            let leftover = try UpdateInstaller.install(staged, at: appURL)
            NSApp.relaunch(removing: leftover)
        } catch {
            try? FileManager.default.removeItem(at: staged.workDir)
            log.error("Thay app lỗi: \(error.localizedDescription)")
            if automatic { failedAutoInstall = update.version }
            let folder = appURL.deletingLastPathComponent().path
            phase = .failed(String(localized: "9clipboard couldn’t replace itself in \(folder) (\(error.localizedDescription)). Download the update from GitHub instead."))
        }
    }
}

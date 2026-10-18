import AppKit
import ClipCore
import Observation
import ServiceManagement

/// Trạng thái cửa sổ Settings. Đọc/ghi thẳng `Preferences`; không dùng @State (Command Line Tools thiếu plugin `SwiftUIMacros`).
@MainActor
@Observable
final class SettingsModel {
    let app: AppModel
    let dataDirectory: URL
    let updater: Updater

    init(app: AppModel, dataDirectory: URL, updater: Updater) {
        self.app = app
        self.dataDirectory = dataDirectory
        self.updater = updater
        refresh()
    }

    /// Đọc lại các giá trị do hệ thống quyết định (quyền, chạy khi đăng nhập, dung lượng, app nguồn).
    /// Gọi mỗi khi cửa sổ thành key, ví dụ lúc người dùng quay về từ System Settings.
    func refresh() {
        isTrusted = PermissionService.isTrusted
        loginStatus = SMAppService.mainApp.status
        excludedApps = Preferences.excludedBundleIDs.map(AppInfo.init(bundleID:))
        Task {
            sourceApps = await app.sourceApps()
            let dir = dataDirectory
            diskUsage = await Task.detached { DataDirectory.diskUsage(of: dir) }.value
        }
    }

    // MARK: - Chung

    static let historyLimits = [100, 200, 500, 1000, 2000]
    static let imageLimits = [5, 10, 20, 50, 100]

    var historyLimit = Preferences.historyLimit {
        didSet { Preferences.historyLimit = historyLimit }
    }
    var maxImageMB = Preferences.maxImageMB {
        didSet { Preferences.maxImageMB = maxImageMB }
    }
    var autoPaste = Preferences.autoPaste {
        didSet { Preferences.autoPaste = autoPaste }
    }
    private(set) var diskUsage = 0

    // MARK: Ngôn ngữ

    var language = AppLanguage.current {
        didSet {
            guard language != oldValue else { return }
            AppLanguage.save(language)
            // Chọn "Theo hệ thống" mà vẫn ra đúng bản dịch đang chạy thì không cần khởi động lại.
            guard language.resolvedLocalization != AppLanguage.running else { return }
            // Hỏi sau khi Picker đóng hẳn, không chạy modal ngay trong lúc SwiftUI ghi binding.
            Task { Self.askToRelaunch() }
        }
    }

    private static func askToRelaunch() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Restart 9clipboard to change the language?")
        alert.informativeText = String(localized: "Your clipboard history and settings are kept.")
        alert.addButton(withTitle: String(localized: "Restart Now"))
        alert.addButton(withTitle: String(localized: "Later"))
        NSApp.bringToFront()
        if alert.runModal() == .alertFirstButtonReturn {
            AppLanguage.relaunch()
        }
    }

    // MARK: Phím tắt

    private(set) var shortcut = Preferences.hotkey
    /// Cảnh báo/lỗi hiện dưới ô ghi phím.
    private(set) var shortcutMessage: String?

    func beginRecording() {
        shortcutMessage = nil
        HotkeyManager.shared.suspend()
    }

    func endRecording() {
        HotkeyManager.shared.resume()
    }

    /// Nhận tổ hợp mới. Trả về false nếu không dùng được (ô ghi phím tiếp tục chờ).
    @discardableResult
    func record(_ new: HotkeyManager.Shortcut) -> Bool {
        guard new.isUsable else {
            shortcutMessage = String(localized: "Use at least one of ⌘, ⌥ or ⌃.")
            return false
        }
        let old = shortcut
        guard HotkeyManager.shared.register(new) else {
            HotkeyManager.shared.register(old)
            HotkeyManager.shared.suspend()
            shortcutMessage = String(localized: "\(new.displayString) is already used by the system or another app. Choose a different shortcut.")
            return false
        }
        // Đang ghi phím thì giữ tạm tắt, `endRecording` sẽ bật lại.
        HotkeyManager.shared.suspend()
        shortcut = new
        Preferences.hotkey = new
        shortcutMessage = new.knownConflict.map { String(localized: "Note: \(new.displayString) is usually “\($0)”; that app will no longer receive it.") }
        return true
    }

    func resetShortcut() {
        shortcutMessage = nil
        if HotkeyManager.shared.register(.default) {
            shortcut = .default
            Preferences.hotkey = .default
        } else {
            HotkeyManager.shared.register(shortcut)
            shortcutMessage = String(localized: "Couldn’t register \(HotkeyManager.Shortcut.default.displayString).")
        }
    }

    // MARK: Chạy khi đăng nhập

    private(set) var loginStatus: SMAppService.Status = .notRegistered
    private(set) var loginError: String?

    var launchAtLogin: Bool {
        get { loginStatus == .enabled || loginStatus == .requiresApproval }
        set {
            loginError = nil
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                loginError = error.localizedDescription
            }
            loginStatus = SMAppService.mainApp.status
        }
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    // MARK: - Riêng tư

    static let passwordLifetimes = [1, 5, 15, 30, 60]

    var detectPasswords = Preferences.detectPasswords {
        didSet { Preferences.detectPasswords = detectPasswords }
    }
    var passwordLifetimeMinutes = Preferences.passwordLifetimeMinutes {
        didSet { Preferences.passwordLifetimeMinutes = passwordLifetimeMinutes }
    }

    struct AppInfo: Identifiable, Hashable {
        var bundleID: String
        var name: String
        var id: String { bundleID }

        init(bundleID: String) {
            self.bundleID = bundleID
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
            name = url.map { FileManager.default.displayName(atPath: $0.path) } ?? bundleID
        }

        var icon: NSImage? {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID).map {
                NSWorkspace.shared.icon(forFile: $0.path)
            }
        }
    }

    private(set) var excludedApps: [AppInfo] = []
    private(set) var sourceApps: [ClipboardStore.SourceApp] = []

    /// Chọn app (.app) để loại trừ hẳn khỏi lịch sử.
    func addExcludedApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.prompt = String(localized: "Exclude")
        guard panel.runModal() == .OK else { return }
        var ids = Preferences.excludedBundleIDs
        for url in panel.urls {
            guard let id = Bundle(url: url)?.bundleIdentifier, !ids.contains(id) else { continue }
            ids.append(id)
        }
        Preferences.excludedBundleIDs = ids
        excludedApps = ids.map(AppInfo.init(bundleID:))
    }

    func removeExcludedApp(_ app: AppInfo) {
        let ids = Preferences.excludedBundleIDs.filter { $0 != app.bundleID }
        Preferences.excludedBundleIDs = ids
        excludedApps = ids.map(AppInfo.init(bundleID:))
    }

    // MARK: - Xoá lịch sử

    /// `nil`: xoá toàn bộ lịch sử. Hỏi lại trước khi xoá; mục đã ghim luôn được giữ.
    func clearHistory(fromApp source: ClipboardStore.SourceApp? = nil) {
        let title = source.map { String(localized: "Delete \($0.count) items copied from \($0.name)?") }
            ?? String(localized: "Clear all history?")
        guard Self.confirm(title, info: Self.clearHistoryInfo, button: String(localized: "Delete"))
        else { return }
        Task {
            await app.clearHistory(fromApp: source?.bundleID)
            refresh()
        }
    }

    static var clearHistoryInfo: String {
        String(localized: "Pinned items are kept. This can’t be undone.")
    }

    /// Hộp thoại xác nhận có nút nguy hiểm. Kích hoạt app trước để hộp thoại không bị che.
    static func confirm(_ title: String, info: String, button: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = info
        alert.alertStyle = .warning
        alert.addButton(withTitle: button).hasDestructiveAction = true
        alert.addButton(withTitle: String(localized: "Cancel"))
        NSApp.bringToFront()
        return alert.runModal() == .alertFirstButtonReturn
    }

    // MARK: - Pinboard

    /// Tên đang sửa dở theo id bảng; chỉ lưu khi Enter hoặc đóng cửa sổ (tránh ghi DB mỗi phím).
    var nameDrafts: [Int64: String] = [:]

    func commitName(of board: Pinboard) {
        guard let id = board.id, let draft = nameDrafts.removeValue(forKey: id) else { return }
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != board.name else { return }
        var board = board
        board.name = name
        Task { await app.updatePinboard(board) }
    }

    func commitAllNames() {
        for board in app.pinboards { commitName(of: board) }
    }

    func setColor(_ hex: String, for board: Pinboard) {
        var board = board
        board.color = hex
        Task { await app.updatePinboard(board) }
    }

    func delete(_ board: Pinboard) {
        guard Self.confirm(
            String(localized: "Delete board “\(board.name)”?"),
            info: String(localized: "Its items are unpinned and moved to the top of your history, not deleted."),
            button: String(localized: "Delete Board"))
        else { return }
        Task { await app.deletePinboard(board) }
    }

    func movePinboards(from source: IndexSet, to destination: Int) {
        var boards = app.pinboards
        boards.move(fromOffsets: source, toOffset: destination)
        Task { await app.reorderPinboards(boards) }
    }

    func createPinboard() {
        Task { await app.createPinboard(name: String(localized: "New Board")) }
    }

    // MARK: - Cập nhật

    var autoCheckUpdates = Preferences.autoCheckUpdates {
        didSet {
            Preferences.autoCheckUpdates = autoCheckUpdates
            if autoCheckUpdates { updater.settingsOpened() }
        }
    }
    var autoInstallUpdates = Preferences.autoInstallUpdates {
        didSet { Preferences.autoInstallUpdates = autoInstallUpdates }
    }
    var includeBetaUpdates = Preferences.includeBetaUpdates {
        didSet {
            guard includeBetaUpdates != oldValue else { return }
            Preferences.includeBetaUpdates = includeBetaUpdates
            updater.channelChanged()
        }
    }

    // MARK: - Quyền

    private(set) var isTrusted = false

    func openAccessibilitySettings() {
        PermissionService.openSettings()
    }
}

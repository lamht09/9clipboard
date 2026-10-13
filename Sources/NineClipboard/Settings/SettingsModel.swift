import AppKit
import ClipCore
import Observation
import ServiceManagement

/// Trạng thái cửa sổ Settings (DESIGN §6.4). Đọc/ghi thẳng `Preferences`; không dùng @State (xem STATE.md).
@MainActor
@Observable
final class SettingsModel {
    let app: AppModel
    let dataDirectory: URL

    init(app: AppModel, dataDirectory: URL) {
        self.app = app
        self.dataDirectory = dataDirectory
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
            shortcutMessage = "Cần ít nhất một phím ⌘, ⌥ hoặc ⌃."
            return false
        }
        let old = shortcut
        guard HotkeyManager.shared.register(new) else {
            HotkeyManager.shared.register(old)
            HotkeyManager.shared.suspend()
            shortcutMessage = "\(new.displayString) đang được hệ thống hoặc app khác dùng. Hãy chọn tổ hợp khác."
            return false
        }
        // Đang ghi phím thì giữ tạm tắt, `endRecording` sẽ bật lại.
        HotkeyManager.shared.suspend()
        shortcut = new
        Preferences.hotkey = new
        shortcutMessage = new.knownConflict.map { "Lưu ý: \(new.displayString) thường dùng cho “\($0)”, app đó sẽ không nhận được phím này nữa." }
        return true
    }

    func resetShortcut() {
        shortcutMessage = nil
        if HotkeyManager.shared.register(.default) {
            shortcut = .default
            Preferences.hotkey = .default
        } else {
            HotkeyManager.shared.register(shortcut)
            shortcutMessage = "Không đăng ký được \(HotkeyManager.Shortcut.default.displayString)."
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
        panel.prompt = "Loại trừ"
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
        let title = source.map { "Xoá \($0.count) mục copy từ \($0.name)?" } ?? "Xoá toàn bộ lịch sử?"
        guard Self.confirm(title, info: "Các mục đã ghim vẫn được giữ lại. Không hoàn tác được.", button: "Xoá")
        else { return }
        Task {
            await app.clearHistory(fromApp: source?.bundleID)
            refresh()
        }
    }

    /// Hộp thoại xác nhận có nút nguy hiểm. Kích hoạt app trước để hộp thoại không bị che.
    static func confirm(_ title: String, info: String, button: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = info
        alert.alertStyle = .warning
        alert.addButton(withTitle: button).hasDestructiveAction = true
        alert.addButton(withTitle: "Huỷ")
        NSApp.activate()
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
            "Xoá bảng “\(board.name)”?",
            info: "Các mục trong bảng được bỏ ghim và đưa lên đầu lịch sử, không bị xoá.",
            button: "Xoá bảng")
        else { return }
        Task { await app.deletePinboard(board) }
    }

    func movePinboards(from source: IndexSet, to destination: Int) {
        var boards = app.pinboards
        boards.move(fromOffsets: source, toOffset: destination)
        Task { await app.reorderPinboards(boards) }
    }

    func createPinboard() {
        Task { await app.createPinboard(name: "Bảng mới") }
    }

    // MARK: - Quyền

    private(set) var isTrusted = false

    func openAccessibilitySettings() {
        PermissionService.openSettings()
    }
}

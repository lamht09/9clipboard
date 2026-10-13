import AppKit
import ClipCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var monitor: ClipboardMonitor?
    private var privacy: PrivacyController?
    private var statusItemController: StatusItemController?
    private var panelController: PanelController?
    private var settingsController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()

        let model: AppModel
        let dir: URL
        do {
            dir = try DataDirectory.url(folder: isDevBuild ? "9clipboard-dev" : "9clipboard")
            let database = try AppDatabase.onDisk(at: dir.appendingPathComponent("clips.sqlite"))
            let blobs = try BlobStore(root: dir)
            model = AppModel(store: ClipboardStore(database: database, blobs: blobs))
        } catch {
            fatalError("Không mở được database: \(error)")
        }
        self.model = model

        let panelController = PanelController(model: model)
        self.panelController = panelController
        let privacy = PrivacyController()
        self.privacy = privacy
        let settingsController = SettingsWindowController(model: SettingsModel(app: model, dataDirectory: dir))
        self.settingsController = settingsController
        let statusItemController = StatusItemController(
            privacy: privacy,
            openPanel: { panelController.show() },
            openSettings: { settingsController.show() },
            clearHistory: {
                guard SettingsModel.confirm(
                    String(localized: "Clear all history?"), info: SettingsModel.clearHistoryInfo,
                    button: String(localized: "Delete")) else { return }
                Task { await model.clearHistory() }
            })
        self.statusItemController = statusItemController
        privacy.onChange = { statusItemController.updateIcon() }

        HotkeyManager.shared.action = { panelController.toggle() }
        let shortcut = Preferences.hotkey
        if !HotkeyManager.shared.register(shortcut) {
            log.error("Không đăng ký được phím tắt \(shortcut.displayString)")
        }

        let monitor = ClipboardMonitor(privacy: privacy) { capture, sensitive in
            Task { await model.ingest(capture, sensitive: sensitive) }
        }
        monitor.start()
        self.monitor = monitor

        model.startExpiryTimer()
        Task { await model.purgeExpired() }
        PermissionService.showOnboardingIfNeeded()
    }
}

import AppKit
import ClipCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var monitor: ClipboardMonitor?
    private var statusItemController: StatusItemController?
    private var panelController: PanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()

        let model: AppModel
        do {
            let dir = try DataDirectory.url()
            let database = try AppDatabase.onDisk(at: dir.appendingPathComponent("clips.sqlite"))
            let blobs = try BlobStore(root: dir)
            model = AppModel(store: ClipboardStore(database: database, blobs: blobs))
        } catch {
            fatalError("Không mở được database: \(error)")
        }
        self.model = model

        let panelController = PanelController(model: model)
        self.panelController = panelController
        statusItemController = StatusItemController(openPanel: { panelController.show() })

        if !HotkeyManager.shared.register(.default, action: { panelController.toggle() }) {
            log.error("Không đăng ký được phím tắt ⌥V")
        }

        let monitor = ClipboardMonitor { capture in
            Task { await model.ingest(capture) }
        }
        monitor.start()
        self.monitor = monitor

        Task { await model.reload() }
        PermissionService.showOnboardingIfNeeded()
    }
}

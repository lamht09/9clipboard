import AppKit
import ClipCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var monitor: ClipboardMonitor?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()

        let model: AppModel
        do {
            let dir = try DataDirectory.url()
            let database = try AppDatabase.onDisk(at: dir.appendingPathComponent("clips.sqlite"))
            model = AppModel(store: ClipboardStore(database: database))
        } catch {
            fatalError("Không mở được database: \(error)")
        }
        self.model = model

        statusItemController = StatusItemController(model: model)

        let monitor = ClipboardMonitor { capture in
            Task { await model.ingest(capture) }
        }
        monitor.start()
        self.monitor = monitor

        Task { await model.reload() }
    }
}

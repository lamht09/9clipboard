import ClipCore
import Foundation
import Observation
import os

let log = Logger(subsystem: "com.9clipboard.app", category: "app")

/// Trạng thái dùng chung giữa menu bar, panel và các service.
@MainActor
@Observable
final class AppModel {
    let store: ClipboardStore
    let previews: PreviewCache
    private(set) var items: [ClipItem] = []

    init(store: ClipboardStore) {
        self.store = store
        previews = PreviewCache(store: store)
    }

    func reload() async {
        do {
            items = try await store.recent()
        } catch {
            log.error("reload failed: \(error.localizedDescription)")
        }
    }

    func ingest(_ capture: Capture) async {
        do {
            try await store.insertOrBump(
                capture,
                historyLimit: Preferences.historyLimit,
                maxImageBytes: Preferences.maxImageMB * 1024 * 1024)
        } catch BlobStore.Error.tooLarge(let bytes) {
            log.notice("bỏ qua ảnh \(bytes / 1024 / 1024) MB, vượt giới hạn \(Preferences.maxImageMB) MB")
            return
        } catch {
            log.error("insert failed: \(error.localizedDescription)")
        }
        await reload()
    }

    func delete(_ item: ClipItem) async {
        guard let id = item.id else { return }
        do {
            try await store.delete(id: id)
        } catch {
            log.error("delete failed: \(error.localizedDescription)")
        }
        await reload()
    }
}

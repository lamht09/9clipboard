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
    private(set) var pinboards: [Pinboard] = []
    /// Tăng sau mỗi lần nạp lại, để panel biết khi nào cần tìm lại.
    private(set) var revision = 0

    init(store: ClipboardStore) {
        self.store = store
        previews = PreviewCache(store: store)
    }

    func reload() async {
        do {
            items = try await store.recent()
            pinboards = try await store.pinboards()
            revision += 1
        } catch {
            log.error("reload failed: \(error.localizedDescription)")
        }
    }

    /// `sensitive`: mật khẩu, tự xoá sau `Preferences.passwordLifetimeMinutes` nếu không được giữ lại.
    func ingest(_ capture: Capture, sensitive: Bool = false) async {
        let lifetime = TimeInterval(Preferences.passwordLifetimeMinutes * 60)
        do {
            try await store.insertOrBump(
                capture,
                historyLimit: Preferences.historyLimit,
                maxImageBytes: Preferences.maxImageMB * 1024 * 1024,
                expiresAt: sensitive ? Date().addingTimeInterval(lifetime) : nil)
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
        await perform("delete") { try await $0.delete(id: id) }
    }

    // MARK: - Mục tự xoá (mật khẩu)

    private var expiryTimer: Timer?

    /// Mỗi 15s xoá các mục đã hết hạn; chỉ nạp lại khi thật sự có mục bị xoá.
    func startExpiryTimer() {
        guard expiryTimer == nil else { return }
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.items.contains(where: \.isExpiring) else { return }
                Task { await self.purgeExpired() }
            }
        }
        timer.tolerance = 3
        RunLoop.main.add(timer, forMode: .common)
        expiryTimer = timer
    }

    func purgeExpired() async {
        do {
            let purged = try await store.purgeExpired()
            if purged > 0 || revision == 0 { await reload() }
        } catch {
            log.error("purgeExpired failed: \(error.localizedDescription)")
        }
    }

    /// Giữ lại mục mật khẩu: không tự xoá nữa.
    func keep(_ item: ClipItem) async {
        guard let id = item.id else { return }
        await perform("keep") { try await $0.keep(itemID: id) }
    }

    // MARK: - Pinboard (M6)

    func pinboard(id: Int64?) -> Pinboard? {
        guard let id else { return nil }
        return pinboards.first { $0.id == id }
    }

    func pin(_ item: ClipItem, to board: Pinboard) async {
        guard let itemID = item.id, let boardID = board.id else { return }
        await perform("pin") { try await $0.pin(itemID: itemID, to: boardID) }
    }

    func pinToDefault(_ item: ClipItem) async {
        guard let id = item.id else { return }
        await perform("pinToDefault") { try await $0.pinToDefault(itemID: id) }
    }

    func unpin(_ item: ClipItem) async {
        guard let id = item.id else { return }
        await perform("unpin") { try await $0.unpin(itemID: id) }
    }

    func movePin(_ item: ClipItem, to index: Int) async {
        guard let id = item.id else { return }
        await perform("movePin") { try await $0.movePin(itemID: id, to: index) }
    }

    /// Tạo bảng mới; có `item` thì ghim luôn vào bảng đó.
    @discardableResult
    func createPinboard(name: String, pinning item: ClipItem? = nil) async -> Pinboard? {
        var created: Pinboard?
        await perform("createPinboard") { store in
            let board = try await store.createPinboard(name: name)
            if let itemID = item?.id, let boardID = board.id {
                try await store.pin(itemID: itemID, to: boardID)
            }
            created = board
        }
        return created
    }

    func updatePinboard(_ board: Pinboard) async {
        await perform("updatePinboard") { try await $0.updatePinboard(board) }
    }

    func deletePinboard(_ board: Pinboard) async {
        guard let id = board.id else { return }
        await perform("deletePinboard") { try await $0.deletePinboard(id: id) }
    }

    func reorderPinboards(_ boards: [Pinboard]) async {
        let ids = boards.compactMap(\.id)
        await perform("reorderPinboards") { try await $0.reorderPinboards(ids) }
    }

    // MARK: - Xoá lịch sử (M8) — mục đã ghim luôn được giữ

    /// `bundleID` = nil: xoá mọi mục chưa ghim.
    func clearHistory(fromApp bundleID: String? = nil) async {
        await perform("clearHistory") { store in
            if let bundleID {
                try await store.clearHistory(fromApp: bundleID)
            } else {
                try await store.clearHistory()
            }
        }
    }

    func sourceApps() async -> [ClipboardStore.SourceApp] {
        (try? await store.sourceApps()) ?? []
    }

    /// Chạy thao tác trên store, ghi log nếu lỗi, rồi nạp lại.
    private func perform(_ name: String, _ operation: (ClipboardStore) async throws -> Void) async {
        do {
            try await operation(store)
        } catch {
            log.error("\(name) failed: \(error.localizedDescription)")
        }
        await reload()
    }
}

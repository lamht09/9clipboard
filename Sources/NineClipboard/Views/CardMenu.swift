import ClipCore
import SwiftUI

/// Các nút thao tác chính ở đầu thẻ đang chọn: ghim, dán text thuần, xoá.
/// Trong tab Pinboard, kéo thẻ thả lên tab bảng khác để chuyển bảng.
/// Dùng tap thay vì Button để không lấy mất focus của ô tìm kiếm; tap trên nút không lan ra thẻ (không dán).
struct CardActionBar: View {
    let viewModel: PanelViewModel
    let item: ClipItem
    let pinboard: Pinboard?

    var body: some View {
        HStack(spacing: 2) {
            if let expiresAt = item.expiresAt {
                // Mật khẩu: bấm để giữ lại, không thì tự xoá khi hết hạn. Ghim cũng là giữ lại.
                action("lock.open", help: String(localized: "Keep · otherwise deleted \(ExpiryText.string(until: expiresAt))")) {
                    viewModel.keep(item)
                }
                .foregroundStyle(Color.orange)
            }
            // Bấm: ghim nhanh vào bảng mặc định / bỏ ghim. Chuột phải: chọn bảng khác.
            action(pinboard == nil ? "pin" : "pin.fill",
                   help: pinboard.map { String(localized: "Unpin from \($0.name) · right-click to move") }
                       ?? String(localized: "Pin to \(Pinboard.defaultName) (⌘P) · right-click to choose a board")) {
                viewModel.togglePin(item)
            }
            .foregroundStyle(pinboard.map { Color(hex: $0.color) } ?? .secondary)
            .contextMenu { PinMenuItems(viewModel: viewModel, item: item) }

            if item.kind != .image {
                action("textformat", help: String(localized: "Paste as Plain Text (⇧↩)")) { viewModel.pick(item, plainOnly: true) }
            }
            action("trash", help: String(localized: "Delete (⌘⌫)")) { viewModel.delete(item) }
        }
        .font(.system(size: 9.5, weight: .medium))
    }

    private func action(_ symbol: String, help: String, perform: @escaping () -> Void) -> some View {
        Image(systemName: symbol)
            .frame(width: 20, height: 18)
            .background(Circle().fill(Color.primary.opacity(0.08)))
            .contentShape(Circle())
            .onTapGesture(perform: perform)
            .help(help)
    }
}

/// Danh sách bảng để ghim, dùng chung cho nút ghim trên thẻ và menu chuột phải.
struct PinMenuItems: View {
    let viewModel: PanelViewModel
    let item: ClipItem

    var body: some View {
        ForEach(viewModel.pinboards) { board in
            Button {
                viewModel.pin(item, to: board)
            } label: {
                Label(board.name, systemImage: board.id == item.pinboardID ? "checkmark" : "pin")
            }
        }
        if !viewModel.pinboards.isEmpty { Divider() }
        Button("New Board…") { viewModel.startCreatingBoard(pinning: item) }
        if item.isPinned {
            Divider()
            Button("Unpin") { viewModel.unpin(item) }
        }
    }
}

/// Menu chuột phải trên thẻ — chỉ là lối phụ, mọi thao tác đều có nút trên thẻ hoặc phím tắt.
struct CardMenu: View {
    let viewModel: PanelViewModel
    let item: ClipItem

    var body: some View {
        Button("Paste") { viewModel.pick(item) }
        if item.kind != .image {
            Button("Paste as Plain Text") { viewModel.pick(item, plainOnly: true) }
        }
        Divider()
        Menu("Pin To") { PinMenuItems(viewModel: viewModel, item: item) }
        if item.isExpiring {
            Button("Keep (don’t auto-delete)") { viewModel.keep(item) }
        }
        Divider()
        Button("Delete") { viewModel.delete(item) }
    }
}

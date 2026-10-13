import ClipCore
import SwiftUI

/// Menu chuột phải trên thẻ.
struct CardMenu: View {
    let viewModel: PanelViewModel
    let item: ClipItem

    var body: some View {
        Button("Dán") { viewModel.pick(item) }
        if item.kind != .image {
            Button("Dán dạng text thuần") { viewModel.pick(item, plainOnly: true) }
        }
        Divider()
        Menu("Ghim vào") {
            ForEach(viewModel.pinboards) { board in
                Button {
                    viewModel.pin(item, to: board)
                } label: {
                    Label(board.name, systemImage: board.id == item.pinboardID ? "checkmark" : "pin")
                }
            }
            if !viewModel.pinboards.isEmpty { Divider() }
            Button("Bảng mới…") { viewModel.startCreatingBoard(pinning: item) }
        }
        if item.isPinned {
            Button("Bỏ ghim") { viewModel.unpin(item) }
        }
        Divider()
        Button("Xoá") {
            viewModel.select(item)
            viewModel.deleteSelected()
        }
    }
}

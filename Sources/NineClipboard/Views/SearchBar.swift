import ClipCore
import SwiftUI

/// Ô tìm kiếm luôn giữ focus khi panel mở, nên gõ ở đâu cũng vào đây (DESIGN §6.2).
/// Dùng TextField thật (không tự bắt phím) để bộ gõ tiếng Việt của hệ thống vẫn hoạt động.
struct SearchBar: View {
    @Bindable var viewModel: PanelViewModel
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Tìm kiếm…", text: $viewModel.query)
                .textFieldStyle(.plain)
                .focused($focused)
            if !viewModel.query.isEmpty {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
                    .onTapGesture { viewModel.query = "" }
            }
        }
        .font(.system(size: 12.5))
        .padding(.horizontal, 10)
        .frame(width: 240, height: PanelLayout.barHeight)
        .background(VisualEffectBackground(cornerRadius: PanelLayout.barHeight / 2))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
        .onAppear { focused = true }
        .onChange(of: viewModel.focusToken) { focused = true }
    }
}

/// Tab lọc: theo loại, rồi các Pinboard (màu theo bảng) và nút `+` tạo bảng.
/// Dùng tap thay vì Button để click không lấy mất focus của ô tìm kiếm.
struct FilterTabs: View {
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        HStack(spacing: 8) {
            group {
                ForEach(ClipFilter.kinds, id: \.self) { tab($0, color: .accentColor) }
            }
            if !viewModel.pinboards.isEmpty || viewModel.boardEditor != nil {
                group {
                    ForEach(viewModel.pinboards) { board in
                        if case .rename(let editing) = viewModel.boardEditor?.mode, editing.id == board.id {
                            BoardNameField(viewModel: viewModel, color: Color(hex: board.color))
                        } else if let id = board.id {
                            tab(.pinboard(id), color: Color(hex: board.color), board: board)
                        }
                    }
                    if case .create = viewModel.boardEditor?.mode {
                        BoardNameField(viewModel: viewModel, color: .accentColor)
                    }
                }
            }
            if viewModel.boardEditor == nil {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: PanelLayout.barHeight, height: PanelLayout.barHeight)
                    .background(VisualEffectBackground(cornerRadius: PanelLayout.barHeight / 2))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
                    .contentShape(Circle())
                    .onTapGesture { viewModel.startCreatingBoard() }
                    .help("Tạo Pinboard mới")
            }
        }
    }

    /// Nhóm tab chung một nền kính mờ dạng viên thuốc.
    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 2, content: content)
            .padding(.horizontal, 3)
            .frame(height: PanelLayout.barHeight)
            .background(VisualEffectBackground(cornerRadius: PanelLayout.barHeight / 2))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
    }

    private func tab(_ filter: ClipFilter, color: Color, board: Pinboard? = nil) -> some View {
        let selected = filter == viewModel.filter
        return HStack(spacing: 5) {
            if board != nil {
                Circle()
                    .fill(selected ? Color.white : color)
                    .frame(width: 6, height: 6)
            }
            Text(viewModel.label(for: filter))
                .lineLimit(1)
        }
        .font(.system(size: 11.5, weight: selected ? .semibold : .regular))
        .foregroundStyle(selected ? Color.white : .primary)
        .padding(.horizontal, 10)
        .frame(height: PanelLayout.barHeight - 6)
        .background(Capsule().fill(selected ? color : .clear))
        .contentShape(Capsule())
        .onTapGesture { viewModel.filter = filter }
        .contextMenu {
            if let board {
                Button("Đổi tên…") { viewModel.startRenaming(board) }
                Menu("Màu") {
                    ForEach(ClipboardStore.pinboardPalette, id: \.self) { hex in
                        Button {
                            viewModel.setColor(hex, for: board)
                        } label: {
                            Label(ColorName.name(for: hex), systemImage: hex == board.color ? "checkmark.circle.fill" : "circle.fill")
                        }
                    }
                }
                Divider()
                Button("Xoá bảng (các mục vẫn còn trong lịch sử)") { viewModel.deleteBoard(board) }
            }
        }
    }
}

/// Ô nhập tên bảng. Enter/Esc do `PanelController` bắt và gọi commit/cancel.
private struct BoardNameField: View {
    @Bindable var viewModel: PanelViewModel
    let color: Color
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            TextField("Tên bảng", text: Binding(
                get: { viewModel.boardEditor?.name ?? "" },
                set: { viewModel.boardEditor?.name = $0 }))
                .textFieldStyle(.plain)
                .frame(width: 110)
                .focused($focused)
        }
        .font(.system(size: 11.5))
        .padding(.horizontal, 10)
        .frame(height: PanelLayout.barHeight - 6)
        .background(Capsule().strokeBorder(color, lineWidth: 1.5))
        .onAppear { focused = true }
    }
}

enum ColorName {
    static func name(for hex: String) -> String {
        switch hex {
        case "#4F8EF7": "Xanh dương"
        case "#F25C54": "Đỏ"
        case "#F7B32B": "Vàng"
        case "#2BB673": "Xanh lá"
        case "#9B5DE5": "Tím"
        case "#00B8D9": "Xanh ngọc"
        case "#FF7AB6": "Hồng"
        default: "Xám"
        }
    }
}

extension Color {
    /// `#RRGGBB`; chuỗi sai định dạng thì ra màu xám.
    init(hex: String) {
        let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x8D99AE
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255)
    }
}

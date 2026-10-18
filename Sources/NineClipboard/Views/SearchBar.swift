import ClipCore
import SwiftUI

/// Ô tìm kiếm luôn giữ focus khi panel mở, nên gõ ở đâu cũng vào đây.
/// Dùng ô nhập thật (không tự bắt phím) để bộ gõ của hệ thống (Telex, pinyin, kana…) vẫn hoạt động.
struct SearchBar: View {
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            SearchField(text: $viewModel.query, placeholder: String(localized: "Search…"),
                        focusToken: viewModel.focusToken)
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
                    .help("New Pinboard")
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
        let isDropTarget = board != nil && board?.id == viewModel.dropTarget?.id
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
        .background(Capsule().fill(selected ? color : isDropTarget ? color.opacity(0.35) : .clear))
        .scaleEffect(isDropTarget ? 1.1 : 1)
        .animation(.easeOut(duration: 0.1), value: isDropTarget)
        .contentShape(Capsule())
        .background(GeometryReader { geo in
            Color.clear.preference(key: TabFramesKey.self, value: [filter: geo.frame(in: .named(PanelLayout.space))])
        })
        .onTapGesture { viewModel.filter = filter }
        .contextMenu {
            if let board {
                Button("Rename…") { viewModel.startRenaming(board) }
                Menu("Color") {
                    ForEach(ClipboardStore.pinboardPalette, id: \.self) { hex in
                        Button {
                            viewModel.setColor(hex, for: board)
                        } label: {
                            Label(ColorName.name(for: hex), systemImage: hex == board.color ? "checkmark.circle.fill" : "circle.fill")
                        }
                    }
                }
                Divider()
                Button("Delete Board (items stay in history)") { viewModel.deleteBoard(board) }
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
            TextField("Board Name", text: Binding(
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
        case "#4F8EF7": String(localized: "Blue")
        case "#F25C54": String(localized: "Red")
        case "#F7B32B": String(localized: "Yellow")
        case "#2BB673": String(localized: "Green")
        case "#9B5DE5": String(localized: "Purple")
        case "#00B8D9": String(localized: "Teal")
        case "#FF7AB6": String(localized: "Pink")
        default: String(localized: "Gray")
        }
    }
}

extension ClipFilter {
    /// Tên tab theo loại; tab Pinboard lấy tên bảng.
    var label: String {
        switch self {
        case .all: String(localized: "All")
        case .text: String(localized: "Text")
        case .link: String(localized: "Link")
        case .image: String(localized: "Image")
        case .pinboard: String(localized: "Pinboard")
        }
    }
}

extension Pinboard {
    /// Bảng nhận mục khi ghim nhanh (⌘P). Tên theo ngôn ngữ giao diện lúc tạo bảng.
    static var defaultName: String { String(localized: "Pinned") }
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

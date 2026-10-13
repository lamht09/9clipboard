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

/// Tab lọc theo loại. Dùng tap thay vì Button để click không lấy mất focus của ô tìm kiếm.
struct FilterTabs: View {
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ClipFilter.allCases, id: \.self) { filter in
                let selected = filter == viewModel.filter
                Text(filter.label)
                    .font(.system(size: 11.5, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Color.white : .primary)
                    .padding(.horizontal, 10)
                    .frame(height: PanelLayout.barHeight - 6)
                    .background(Capsule().fill(selected ? Color.accentColor : .clear))
                    .contentShape(Capsule())
                    .onTapGesture { viewModel.filter = filter }
            }
        }
        .padding(.horizontal, 3)
        .frame(height: PanelLayout.barHeight)
        .background(VisualEffectBackground(cornerRadius: PanelLayout.barHeight / 2))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
    }
}

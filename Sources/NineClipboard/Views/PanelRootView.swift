import ClipCore
import SwiftUI

enum PanelLayout {
    static let barHeight: CGFloat = 30
    /// Không gian toạ độ chung để so vị trí thẻ đang kéo với khung các tab.
    static let space = "panel"
    /// Lề trên thanh tìm kiếm để bóng đổ không bị mép panel cắt.
    static let barTop: CGFloat = 4
    /// Thanh tìm kiếm + dải thẻ (thẻ + lề chứa hiệu ứng phóng to và bóng đổ).
    static let height: CGFloat = barTop + barHeight + StripLayout.cardSize + StripLayout.verticalInset * 2
}

struct TabFramesKey: PreferenceKey {
    static let defaultValue: [ClipFilter: CGRect] = [:]
    static func reduce(value: inout [ClipFilter: CGRect], nextValue: () -> [ClipFilter: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct PanelRootView: View {
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                SearchBar(viewModel: viewModel)
                FilterTabs(viewModel: viewModel)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, StripLayout.inset)
            .frame(height: PanelLayout.barHeight)
            .padding(.top, PanelLayout.barTop)
            CardStrip(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: PanelLayout.space)
        .onPreferenceChange(TabFramesKey.self) { frames in
            MainActor.assumeIsolated { viewModel.tabFrames = frames }
        }
        .ignoresSafeArea()
    }
}

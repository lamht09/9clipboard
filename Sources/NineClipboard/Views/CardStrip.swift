import ClipCore
import SwiftUI

/// Kích thước và vị trí thẻ trong dải.
enum StripLayout {
    static let cardSize: CGFloat = 150
    static let spacing: CGFloat = 10
    static let inset: CGFloat = 14
    /// Lề trên/dưới, đủ chứa phóng to 1.03, viền chọn và bóng đổ.
    static let verticalInset: CGFloat = 14
    static let fadeWidth: CGFloat = 56
    static var step: CGFloat { cardSize + spacing }

    static func cardX(_ index: Int) -> CGFloat { inset + CGFloat(index) * step }

    static func contentWidth(count: Int) -> CGFloat {
        count == 0 ? 0 : inset * 2 + CGFloat(count) * step - spacing
    }
}

struct CardStrip: View {
    @Bindable var viewModel: PanelViewModel

    private struct Slot: Identifiable {
        let index: Int
        let item: ClipItem
        var id: Int64? { item.id }
    }

    var body: some View {
        GeometryReader { geo in
            let items = viewModel.items
            let slots = viewModel.visibleRange().map { Slot(index: $0, item: items[$0]) }
            ZStack(alignment: .topLeading) {
                ForEach(slots) { slot in
                    CardView(item: slot.item, index: slot.index, isSelected: slot.index == viewModel.selectedIndex,
                             previews: viewModel.previews, highlight: viewModel.activeQuery)
                        // Click một lần là dán luôn; rê chuột qua thì chọn.
                        .onTapGesture { viewModel.click(slot.item) }
                        .onHover { inside in if inside { viewModel.select(slot.item) } }
                        .offset(x: StripLayout.cardX(slot.index) - viewModel.scrollOffset,
                                y: StripLayout.verticalInset)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { viewModel.dragChanged(translation: $0.translation.width) }
                    .onEnded { viewModel.dragEnded(predictedTranslation: $0.predictedEndTranslation.width) }
            )
            .mask(edgeFade(width: geo.size.width))
            .overlay {
                if items.isEmpty {
                    Text(viewModel.emptyMessage)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(VisualEffectBackground(cornerRadius: 10))
                }
            }
            .onAppear { viewModel.viewportWidth = geo.size.width }
            .onChange(of: geo.size.width) { _, width in viewModel.viewportWidth = width }
        }
    }

    /// Làm mờ dần thẻ bị cắt ở hai mép; mép nào chưa có gì bị cắt thì không mờ.
    private func edgeFade(width: CGFloat) -> LinearGradient {
        let fade = width > 0 ? min(StripLayout.fadeWidth / width, 0.25) : 0
        let left = viewModel.scrollOffset > 1 ? fade : 0
        let right = viewModel.scrollOffset < viewModel.maxOffset - 1 ? fade : 0
        return LinearGradient(
            stops: [
                .init(color: left > 0 ? .clear : .black, location: 0),
                .init(color: .black, location: left),
                .init(color: .black, location: 1 - right),
                .init(color: right > 0 ? .clear : .black, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

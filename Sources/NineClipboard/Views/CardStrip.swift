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
                    let dragging = slot.index == viewModel.reorderIndex
                    CardView(item: slot.item, index: slot.index, isSelected: slot.index == viewModel.selectedIndex,
                             previews: viewModel.previews, highlight: viewModel.activeQuery,
                             pinboard: viewModel.pinboard(for: slot.item), viewModel: viewModel)
                        // Click một lần là dán luôn; rê chuột qua thì chọn.
                        .onTapGesture { viewModel.click(slot.item) }
                        .onHover { inside in if inside && viewModel.reorderIndex == nil { viewModel.select(slot.item) } }
                        .contextMenu { CardMenu(viewModel: viewModel, item: slot.item) }
                        // Trong tab Pinboard, kéo thẻ để sắp xếp (kéo khoảng trống vẫn là cuộn).
                        // Kéo lên thả vào tab bảng khác để chuyển mục sang bảng đó.
                        .gesture(
                            DragGesture(minimumDistance: 4, coordinateSpace: .named(PanelLayout.space))
                                .onChanged {
                                    viewModel.reorderChanged(index: slot.index, translation: $0.translation, location: $0.location)
                                }
                                .onEnded { _ in viewModel.reorderEnded() },
                            including: viewModel.canReorder ? .all : .subviews)
                        .scaleEffect(dragging && viewModel.dropTarget != nil ? 0.5 : 1)
                        .zIndex(dragging ? 1 : 0)
                        .shadow(color: .black.opacity(dragging ? 0.3 : 0), radius: 10, y: 4)
                        .offset(viewModel.reorderOffset(for: slot.index))
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
            // Mask kéo dài lên trên để thẻ đang kéo lên thanh tab không bị cắt mất.
            .mask {
                edgeFade(width: geo.size.width)
                    .padding(.top, -(PanelLayout.barTop + PanelLayout.barHeight))
            }
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

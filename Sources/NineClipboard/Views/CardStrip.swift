import ClipCore
import SwiftUI

struct CardStrip: View {
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        CardView(item: item, index: index, isSelected: index == viewModel.selectedIndex)
                            .id(item.id)
                            // Click một lần là dán luôn; rê chuột qua thì chọn.
                            .onTapGesture { viewModel.pick(item) }
                            .onHover { inside in if inside { viewModel.select(item) } }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }
            .overlay {
                if viewModel.items.isEmpty {
                    Text("Chưa có gì trong lịch sử. Hãy copy thứ gì đó.")
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: viewModel.scrollTarget) { _, id in
                guard let id else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
            .onChange(of: viewModel.openToken) { _, _ in
                if let first = viewModel.items.first { proxy.scrollTo(first.id, anchor: .leading) }
            }
        }
    }
}

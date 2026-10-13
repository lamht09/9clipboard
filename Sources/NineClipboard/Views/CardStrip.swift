import ClipCore
import SwiftUI

struct CardStrip: View {
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        CardView(item: item, index: index, isSelected: index == viewModel.selectedIndex)
                            .id(item.id)
                            .onTapGesture(count: 2) { viewModel.pick(item) }
                            .onTapGesture { viewModel.select(item) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .overlay {
                if viewModel.items.isEmpty {
                    Text("Chưa có gì trong lịch sử. Hãy copy thứ gì đó.")
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: viewModel.selectedIndex) { _, index in
                guard viewModel.items.indices.contains(index) else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(viewModel.items[index].id, anchor: .center)
                }
            }
            .onChange(of: viewModel.openToken) { _, _ in
                if let first = viewModel.items.first { proxy.scrollTo(first.id, anchor: .leading) }
            }
        }
    }
}

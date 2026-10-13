import ClipCore
import SwiftUI

struct PanelRootView: View {
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardStrip(viewModel: viewModel)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

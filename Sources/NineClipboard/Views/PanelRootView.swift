import ClipCore
import SwiftUI

struct PanelRootView: View {
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        CardStrip(viewModel: viewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}

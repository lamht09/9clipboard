import AppKit
import ClipCore
import Observation
import SwiftUI

/// Xem trước cỡ lớn (phím Space): nổi phía trên dải thẻ, đi theo thẻ đang chọn.
struct LargePreviewView: View {
    var viewModel: PanelViewModel
    var loader: LargePreviewLoader

    var body: some View {
        Group {
            if let item = viewModel.selectedItem {
                VStack(alignment: .leading, spacing: 0) {
                    header(for: item)
                    Divider().opacity(0.5)
                    content(for: item)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .task(id: item.contentHash) { await loader.load(item) }
            } else {
                Color.clear
            }
        }
        .background(VisualEffectBackground(cornerRadius: 12))
        .background(Color(nsColor: .textBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)) }
        .padding(10) // chỗ cho bóng đổ
        .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
        .ignoresSafeArea()
    }

    private func header(for item: ClipItem) -> some View {
        HStack(spacing: 6) {
            Circle().fill(item.kind.color).frame(width: 7, height: 7)
            Text(item.kind.label).fontWeight(.semibold)
            if let icon = AppIconCache.icon(for: item.sourceBundleID) {
                Image(nsImage: icon).resizable().frame(width: 14, height: 14)
            }
            Text(item.sourceAppName ?? "")
            Spacer()
            Text(Self.detail(for: item))
            Text("Space to close").foregroundStyle(.tertiary)
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .frame(height: 30)
    }

    @ViewBuilder
    private func content(for item: ClipItem) -> some View {
        switch loader.content(for: item) {
        case .image(let image):
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .padding(12)
        case .text(let text):
            ScrollableText(text: text)
        case nil:
            ProgressView().controlSize(.small)
        }
    }

    private static func detail(for item: ClipItem) -> String {
        var parts = [RelativeTime.string(for: item.lastUsedAt)]
        if let w = item.imageWidth, let h = item.imageHeight {
            parts.append("\(w)×\(h)")
        } else if let text = item.plainText {
            parts.append(String(localized: "\(text.count) characters"))
        }
        parts.append(ByteCountFormatter.string(fromByteCount: Int64(item.byteSize), countStyle: .file))
        return parts.joined(separator: " · ")
    }
}

/// Nạp nội dung đầy đủ (ảnh gốc, rich text, text dài) cho xem trước. Giữ vài mục gần nhất.
@MainActor
@Observable
final class LargePreviewLoader {
    enum Content {
        case image(NSImage)
        case text(NSAttributedString)
    }

    private let store: ClipboardStore
    private var cache: [String: Content] = [:]
    @ObservationIgnored private var order: [String] = []

    init(store: ClipboardStore) {
        self.store = store
    }

    func content(for item: ClipItem) -> Content? {
        cache[item.contentHash]
    }

    func load(_ item: ClipItem) async {
        let key = item.contentHash
        guard cache[key] == nil, let id = item.id else { return }
        let reps = (try? await store.representations(itemID: id)) ?? []
        let content: Content
        if item.kind == .image,
           let path = reps.compactMap(\.blobPath).first,
           let image = NSImage(contentsOf: store.blobs.url(forBlob: path)) {
            content = .image(image)
        } else if item.kind == .rich,
                  let rtf = reps.first(where: { $0.uti == UTI.rtf })?.data,
                  let rich = Self.richText(fromRTF: rtf) {
            content = .text(rich)
        } else {
            content = .text(Self.plainText(item))
        }
        cache[key] = content
        order.append(key)
        if order.count > 20 { cache[order.removeFirst()] = nil }
    }

    func clear() {
        cache.removeAll()
        order.removeAll()
    }

    private static func plainText(_ item: ClipItem) -> NSAttributedString {
        let font = CodeApps.isCodeApp(item.sourceBundleID)
            ? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            : NSFont.systemFont(ofSize: 13)
        return NSAttributedString(
            string: String((item.plainText ?? "").prefix(200_000)),
            attributes: [.font: font, .foregroundColor: NSColor.labelColor])
    }

    /// Giữ font/đậm/nghiêng của nguồn, bỏ màu chữ/nền để đọc được ở cả Sáng/Tối.
    private static func richText(fromRTF data: Data) -> NSAttributedString? {
        guard data.count <= 4 * 1024 * 1024,
              let full = NSAttributedString(rtf: data, documentAttributes: nil),
              full.length > 0
        else { return nil }
        let ns = NSMutableAttributedString(attributedString: full)
        let range = NSRange(location: 0, length: ns.length)
        ns.removeAttribute(.backgroundColor, range: range)
        ns.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
        return ns
    }
}

/// NSTextView chỉ đọc, chọn được chữ, cuộn dọc.
private struct ScrollableText: NSViewRepresentable {
    var text: NSAttributedString

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        if let textView = scroll.documentView as? NSTextView {
            textView.isEditable = false
            textView.isSelectable = true
            textView.drawsBackground = false
            textView.textContainerInset = NSSize(width: 8, height: 8)
        }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView,
              textView.textStorage?.isEqual(to: text) != true
        else { return }
        textView.textStorage?.setAttributedString(text)
        textView.scrollToBeginningOfDocument(nil)
    }
}

/// Cửa sổ xem trước: không bao giờ thành key, để panel chính vẫn nhận bàn phím.
final class PreviewPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: true)
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        hidesOnDeactivate = false
        isMovable = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

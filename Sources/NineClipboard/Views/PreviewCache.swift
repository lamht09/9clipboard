import AppKit
import ClipCore
import Observation
import SwiftUI

/// Nạp và giữ sẵn phần xem trước của thẻ: thumbnail ảnh và rich text dựng từ RTF.
/// Khoá theo `content_hash` (id SQLite có thể bị dùng lại sau khi xoá).
@MainActor
@Observable
final class PreviewCache {
    private let store: ClipboardStore
    @ObservationIgnored private let thumbnails = NSCache<NSString, NSImage>()
    private var richTexts: [String: AttributedString] = [:]
    /// Mục đã nạp (kể cả nạp hỏng), để không nạp lại liên tục khi view vẽ lại.
    @ObservationIgnored private var requested: Set<String> = []
    /// Bản tô sáng theo chuỗi tìm hiện tại; đổi chuỗi tìm thì bỏ hết.
    @ObservationIgnored private var highlightQuery = ""
    @ObservationIgnored private var highlights: [String: AttributedString] = [:]

    init(store: ClipboardStore) {
        self.store = store
        thumbnails.countLimit = 200
    }

    /// Thumbnail JPEG/PNG nhỏ (≤ 400px) nên đọc thẳng từ đĩa trên main thread được.
    func thumbnail(for item: ClipItem) -> NSImage? {
        let key = item.contentHash as NSString
        if let cached = thumbnails.object(forKey: key) { return cached }
        guard let url = store.blobs.thumbnailURL(for: item.contentHash),
              let image = NSImage(contentsOf: url)
        else { return nil }
        thumbnails.setObject(image, forKey: key)
        return image
    }

    /// Rich text đã thu nhỏ cho thẻ. Trả nil khi chưa nạp xong (thẻ tạm hiện plain text) hoặc không có RTF.
    func richText(for item: ClipItem) -> AttributedString? {
        guard item.kind == .rich, let id = item.id else { return nil }
        let key = item.contentHash
        if let cached = richTexts[key] { return cached }
        guard !requested.contains(key) else { return nil }
        requested.insert(key)
        Task {
            let reps = (try? await store.representations(itemID: id)) ?? []
            if let rtf = reps.first(where: { $0.uti == UTI.rtf })?.data,
               let preview = Self.cardPreview(fromRTF: rtf) {
                richTexts[key] = preview
            }
        }
        return nil
    }

    // MARK: - Tô sáng phần khớp tìm kiếm

    /// Plain text có tô sáng. Nếu chỗ khớp đầu tiên nằm sâu trong text thì cắt bớt phần đầu
    /// (thêm "…") để chỗ khớp lọt vào 6 dòng của thẻ.
    func highlightedPlainText(for item: ClipItem, query: String) -> AttributedString? {
        cachedHighlight(key: item.contentHash + "|plain", query: query) {
            let full = (item.plainText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let ranges = Highlighter.ranges(of: query, in: full)
            var start = 0
            if let first = ranges.first, first.lowerBound > 80 { start = first.lowerBound - 30 }
            let body = String(full[full.index(full.startIndex, offsetBy: start)...].prefix(600))
            var text = AttributedString(start > 0 ? "…" + body : body)
            Self.apply(ranges, shift: (start > 0 ? 1 : 0) - start, to: &text)
            return text
        }
    }

    /// Rich text (đã dựng sẵn) có tô sáng.
    func highlighted(_ rich: AttributedString, item: ClipItem, query: String) -> AttributedString? {
        cachedHighlight(key: item.contentHash + "|rich", query: query) {
            var text = rich
            Self.apply(Highlighter.ranges(of: query, in: String(rich.characters)), shift: 0, to: &text)
            return text
        }
    }

    private func cachedHighlight(key: String, query: String, make: () -> AttributedString) -> AttributedString? {
        guard !query.isEmpty else { return nil }
        if query != highlightQuery {
            highlights.removeAll()
            highlightQuery = query
        }
        if let cached = highlights[key] { return cached }
        let text = make()
        highlights[key] = text
        return text
    }

    private static func apply(_ ranges: [Range<Int>], shift: Int, to text: inout AttributedString) {
        let count = text.characters.count
        for range in ranges {
            let lower = range.lowerBound + shift
            let upper = min(range.upperBound + shift, count)
            guard lower >= 0, lower < upper else { continue }
            let start = text.characters.index(text.startIndex, offsetBy: lower)
            let end = text.characters.index(start, offsetBy: upper - lower)
            text[start..<end].backgroundColor = Color.yellow.opacity(0.45)
        }
    }

    /// Dựng AttributedString cho thẻ: giữ đậm/nghiêng/gạch chân, thu nhỏ cỡ chữ về 10–15pt,
    /// bỏ màu chữ/nền và khoảng cách đoạn của nguồn để đọc được ở cả chế độ Sáng/Tối.
    static func cardPreview(fromRTF data: Data) -> AttributedString? {
        guard data.count <= 512 * 1024,
              let full = NSAttributedString(rtf: data, documentAttributes: nil),
              full.length > 0
        else { return nil }
        let ns = NSMutableAttributedString(attributedString: full.attributedSubstring(
            from: NSRange(location: 0, length: min(full.length, 600))))
        let range = NSRange(location: 0, length: ns.length)
        for key: NSAttributedString.Key in [.foregroundColor, .backgroundColor, .paragraphStyle, .link] {
            ns.removeAttribute(key, range: range)
        }
        ns.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let font = (value as? NSFont) ?? .systemFont(ofSize: 13)
            let size = min(max(font.pointSize * 0.85, 10), 15)
            ns.addAttribute(.font, value: NSFontManager.shared.convert(font, toSize: size), range: subrange)
        }
        return try? AttributedString(ns, including: \.appKit)
    }
}

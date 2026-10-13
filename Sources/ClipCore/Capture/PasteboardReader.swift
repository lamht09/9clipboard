import AppKit
import Foundation

/// Nguồn pasteboard trừu tượng để test được mà không cần `NSPasteboard` thật.
public protocol PasteboardSource {
    var changeCount: Int { get }
    var typeIdentifiers: [String] { get }
    func data(forType uti: String) -> Data?
}

extension NSPasteboard: PasteboardSource {
    public var typeIdentifiers: [String] { types?.map(\.rawValue) ?? [] }
    public func data(forType uti: String) -> Data? { data(forType: NSPasteboard.PasteboardType(uti)) }
}

public enum PasteboardReader {
    /// Đọc pasteboard thành `Capture`. Trả về nil nếu không có nội dung hỗ trợ.
    public static func read(
        from source: PasteboardSource,
        sourceBundleID: String? = nil,
        sourceAppName: String? = nil
    ) -> Capture? {
        let types = Set(source.typeIdentifiers)
        func nonEmptyData(_ uti: String) -> Data? {
            guard types.contains(uti), let data = source.data(forType: uti), !data.isEmpty else { return nil }
            return data
        }
        let formatted = [UTI.rtf, UTI.html].compactMap { uti in nonEmptyData(uti).map { Capture.Item(uti: uti, data: $0) } }

        // Có text: text / link / rich. Giữ cả RTF/HTML để dán lại đủ định dạng.
        if let data = nonEmptyData(UTI.plainText),
           let text = String(data: data, encoding: .utf8),
           !isBlank(text) {
            let kind: ClipKind = isLink(text) ? .link : (formatted.isEmpty ? .text : .rich)
            return Capture(
                kind: kind,
                plainText: text,
                representations: [.init(uti: UTI.plainText, data: data)] + formatted,
                sourceBundleID: sourceBundleID,
                sourceAppName: sourceAppName
            )
        }

        // Không có text: ảnh. Ưu tiên PNG; TIFF sẽ được đổi sang PNG khi lưu (BlobStore).
        for uti in [UTI.png, UTI.tiff] {
            guard let data = nonEmptyData(uti), let size = ImageCodec.pixelSize(of: data) else { continue }
            return Capture(
                kind: .image,
                plainText: nil,
                representations: [.init(uti: uti, data: data)],
                sourceBundleID: sourceBundleID,
                sourceAppName: sourceAppName,
                imageWidth: size.width,
                imageHeight: size.height
            )
        }

        // Hiếm: chỉ có RTF mà không kèm plain text → tự rút text ra.
        if let rtf = formatted.first(where: { $0.uti == UTI.rtf }),
           let text = NSAttributedString(rtf: rtf.data, documentAttributes: nil)?.string,
           !isBlank(text) {
            return Capture(
                kind: .rich,
                plainText: text,
                representations: [.init(uti: UTI.plainText, data: Data(text.utf8))] + formatted,
                sourceBundleID: sourceBundleID,
                sourceAppName: sourceAppName
            )
        }
        return nil
    }

    private static func isBlank(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Plain text mà sau khi trim là một URL http/https hợp lệ.
    public static func isLink(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(where: \.isWhitespace),
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty
        else { return false }
        return true
    }
}

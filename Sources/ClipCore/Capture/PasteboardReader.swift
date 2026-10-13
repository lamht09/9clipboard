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

        guard types.contains(UTI.plainText),
              let data = source.data(forType: UTI.plainText),
              let text = String(data: data, encoding: .utf8),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }

        let kind: ClipKind = isLink(text) ? .link : .text
        return Capture(
            kind: kind,
            plainText: text,
            representations: [.init(uti: UTI.plainText, data: data)],
            sourceBundleID: sourceBundleID,
            sourceAppName: sourceAppName
        )
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

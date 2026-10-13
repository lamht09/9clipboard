import Foundation
import GRDB

/// Một định dạng (UTI) của lần copy. Text/RTF/HTML lưu thẳng trong `data`, ảnh lưu file và giữ `blobPath`.
public struct Representation: Codable, Sendable, Hashable {
    public var itemID: Int64
    public var uti: String
    public var data: Data?
    public var blobPath: String?

    public init(itemID: Int64, uti: String, data: Data? = nil, blobPath: String? = nil) {
        self.itemID = itemID
        self.uti = uti
        self.data = data
        self.blobPath = blobPath
    }

    enum CodingKeys: String, CodingKey {
        case itemID = "item_id"
        case uti, data
        case blobPath = "blob_path"
    }
}

extension Representation: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "representation"
}

public enum UTI {
    public static let plainText = "public.utf8-plain-text"
    public static let rtf = "public.rtf"
    public static let html = "public.html"
    public static let png = "public.png"
    public static let tiff = "public.tiff"
    /// Đánh dấu nội dung do chính 9clipboard ghi lên pasteboard, để monitor bỏ qua.
    public static let selfMarker = "com.9clipboard.self"
}

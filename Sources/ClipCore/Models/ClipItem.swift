import Foundation
import GRDB

public enum ClipKind: String, Codable, Sendable, CaseIterable, DatabaseValueConvertible {
    case text, rich, image, link
}

public struct ClipItem: Codable, Sendable, Identifiable, Hashable {
    public var id: Int64?
    public var kind: ClipKind
    public var contentHash: String
    public var plainText: String?
    public var searchKey: String?
    public var sourceBundleID: String?
    public var sourceAppName: String?
    public var byteSize: Int
    public var imageWidth: Int?
    public var imageHeight: Int?
    public var createdAt: Date
    public var lastUsedAt: Date
    public var useCount: Int
    public var pinboardID: Int64?
    public var pinOrder: Int?
    /// Mục nhạy cảm (mật khẩu) tự xoá lúc này nếu người dùng không giữ lại. `nil` = giữ vĩnh viễn.
    public var expiresAt: Date? = nil
    /// Khoá tìm theo cách đọc (pinyin, romaji, phụ âm đầu Hangul). Xem `PhoneticKey`.
    public var phoneticKey: String? = nil

    public var isPinned: Bool { pinboardID != nil }
    public var isExpiring: Bool { expiresAt != nil }

    enum CodingKeys: String, CodingKey {
        case id, kind
        case contentHash = "content_hash"
        case plainText = "plain_text"
        case searchKey = "search_key"
        case sourceBundleID = "source_bundle_id"
        case sourceAppName = "source_app_name"
        case byteSize = "byte_size"
        case imageWidth = "image_width"
        case imageHeight = "image_height"
        case createdAt = "created_at"
        case lastUsedAt = "last_used_at"
        case useCount = "use_count"
        case pinboardID = "pinboard_id"
        case pinOrder = "pin_order"
        case expiresAt = "expires_at"
        case phoneticKey = "phonetic_key"
    }
}

extension ClipItem: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "clip_item"

    // Lưu ngày dạng REAL (giây từ 1970) để ORDER BY đúng và khớp schema.
    public static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy {
        .timeIntervalSince1970
    }

    public static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy {
        .timeIntervalSince1970
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

import Foundation

/// Tab lọc trong panel: theo loại, hoặc theo một Pinboard.
public enum ClipFilter: Hashable, Sendable {
    case all, text, link, image
    case pinboard(Int64)

    /// Các tab theo loại, đứng trước các tab Pinboard.
    public static let kinds: [ClipFilter] = [.all, .text, .link, .image]

    /// Tên tab theo loại; tab Pinboard lấy tên bảng.
    public var label: String {
        switch self {
        case .all: "Tất cả"
        case .text: "Text"
        case .link: "Link"
        case .image: "Ảnh"
        case .pinboard: "Pinboard"
        }
    }

    public func includes(_ item: ClipItem) -> Bool {
        switch self {
        case .all: true
        case .text: item.kind == .text || item.kind == .rich
        case .link: item.kind == .link
        case .image: item.kind == .image
        case .pinboard(let id): item.pinboardID == id
        }
    }
}

/// Lọc và xếp hạng lịch sử theo chuỗi tìm (DESIGN §7). Giữ sẵn `search_key` dạng mảng scalar
/// theo `content_hash` để mỗi lần gõ không phải chuyển đổi lại. Chỉ dùng trên một luồng.
public final class SearchEngine {
    public struct Result: Sendable {
        public var item: ClipItem
        public var score: Double
    }

    private var keys: [String: [UInt32]] = [:]

    public init() {}

    /// `items` đã sắp theo `last_used_at` giảm dần. Chuỗi tìm trống thì chỉ lọc, giữ nguyên thứ tự
    /// (tab Pinboard thì theo `pin_order`).
    public func search(_ items: [ClipItem], query: String, filter: ClipFilter) -> [Result] {
        var filtered = items.filter(filter.includes)
        if case .pinboard = filter {
            filtered.sort { ($0.pinOrder ?? .max, $0.id ?? 0) < ($1.pinOrder ?? .max, $1.id ?? 0) }
        }
        let q = FuzzyMatcher.scalars(TextNormalizer.normalize(query))
        guard !q.isEmpty else { return filtered.map { Result(item: $0, score: 0) } }

        if keys.count > max(items.count * 2, 256) { keys.removeAll(keepingCapacity: true) }
        let denominator = Double(max(filtered.count - 1, 1))
        var results: [(Result, rank: Int)] = []
        for (rank, item) in filtered.enumerated() {
            guard let match = FuzzyMatcher.match(q, in: key(for: item)) else { continue }
            let recency = 1 - Double(rank) / denominator
            results.append((Result(item: item, score: match.score * 0.8 + recency * 0.2), rank))
        }
        results.sort { $0.0.score != $1.0.score ? $0.0.score > $1.0.score : $0.rank < $1.rank }
        return results.map(\.0)
    }

    private func key(for item: ClipItem) -> [UInt32] {
        if let cached = keys[item.contentHash] { return cached }
        let normalized = item.searchKey ?? item.plainText.map(TextNormalizer.normalize) ?? ""
        let key = FuzzyMatcher.scalars(normalized)
        keys[item.contentHash] = key
        return key
    }
}

import Foundation

/// Chấm điểm khớp giữa chuỗi tìm và một mục. Cả hai đều đã qua `TextNormalizer`
/// và được chuyển thành mảng scalar để so sánh nhanh.
public enum FuzzyMatcher {
    public struct Match: Sendable, Equatable {
        /// 0…1. Khớp liên tục luôn ≥ 0.7, subsequence luôn ≤ 0.6.
        public var score: Double
        /// Vị trí (trong mảng scalar của text) các ký tự khớp, tăng dần.
        public var positions: [Int]
    }

    /// Chỉ xét chừng này scalar đầu của mỗi mục, để mục rất dài (log, file dán vào) không làm chậm tìm kiếm.
    public static let maxTextLength = 4096
    static let space = UInt32(UInt8(ascii: " "))

    public static func scalars(_ normalized: String) -> [UInt32] {
        normalized.unicodeScalars.prefix(maxTextLength).map(\.value)
    }

    public static func match(_ query: [UInt32], in text: [UInt32]) -> Match? {
        guard !query.isEmpty, query.count <= text.count else { return nil }
        if let match = substring(query, in: text) { return match }
        return subsequence(query.filter { $0 != space }, in: text)
    }

    /// Khớp liên tục. Ưu tiên lần xuất hiện ở đầu từ; cộng thêm nếu ở ngay đầu text.
    private static func substring(_ query: [UInt32], in text: [UInt32]) -> Match? {
        let first = query[0]
        var found: Int?
        var i = 0
        while i <= text.count - query.count {
            if text[i] == first && matchesAt(i, query, text) {
                if isWordStart(i, text) { found = i; break }
                if found == nil { found = i }
            }
            i += 1
        }
        guard let start = found else { return nil }
        let score = 0.7 + (isWordStart(start, text) ? 0.2 : 0) + (start == 0 ? 0.1 : 0)
        return Match(score: score, positions: Array(start..<start + query.count))
    }

    private static func matchesAt(_ start: Int, _ query: [UInt32], _ text: [UInt32]) -> Bool {
        for j in 1..<query.count where text[start + j] != query[j] { return false }
        return true
    }

    /// Các ký tự xuất hiện đúng thứ tự. Thử từng điểm bắt đầu, lấy cách khớp gọn nhất;
    /// khớp trải quá rộng thì loại, vì text dài gần như luôn chứa mọi subsequence ngắn.
    private static func subsequence(_ query: [UInt32], in text: [UInt32]) -> Match? {
        let m = query.count
        guard m > 0 else { return nil }
        let maxSpan = m * 5 + 8
        var best: (span: Int, wordStarts: Int, positions: [Int])?
        var positions = [Int](repeating: 0, count: m)

        var start = 0
        starts: while start < text.count {
            guard text[start] == query[0] else { start += 1; continue }
            positions[0] = start
            var j = 1
            var i = start + 1
            while j < m {
                guard i < text.count else { break starts }  // từ đây về sau không thể khớp đủ
                if i - start >= maxSpan { start += 1; continue starts }
                if text[i] == query[j] {
                    positions[j] = i
                    j += 1
                }
                i += 1
            }
            let span = positions[m - 1] - start + 1
            let wordStarts = positions.reduce(0) { $0 + (isWordStart($1, text) ? 1 : 0) }
            if best == nil || span < best!.span || (span == best!.span && wordStarts > best!.wordStarts) {
                best = (span, wordStarts, positions)
                if span == m { break }
            }
            start += 1
        }
        guard let best else { return nil }
        let score = 0.2 + 0.25 * Double(m) / Double(best.span) + 0.15 * Double(best.wordStarts) / Double(m)
        return Match(score: score, positions: best.positions)
    }

    static func isWordStart(_ i: Int, _ text: [UInt32]) -> Bool {
        i == 0 || !isAlphanumeric(text[i - 1])
    }

    private static func isAlphanumeric(_ c: UInt32) -> Bool {
        switch c {
        case 0x30...0x39, 0x61...0x7A, 0x41...0x5A: true
        case 0..<0x80: false
        // Ngoài ASCII: chữ (Kirin, Hán, kana, Hangul…) và số; dấu câu như «» 「」 。 — thì không.
        default: Unicode.Scalar(c).map { $0.properties.isAlphabetic || $0.properties.numericType != nil } ?? false
        }
    }
}

import Foundation

/// Tìm phần khớp với chuỗi tìm trên text gốc (còn dấu) để tô sáng trên thẻ.
public enum Highlighter {
    /// Các đoạn khớp, tính theo offset `Character` trong `text`. Chỉ xét `maxCharacters` ký tự đầu.
    public static func ranges(of query: String, in text: String, maxCharacters: Int = 3000) -> [Range<Int>] {
        let q = FuzzyMatcher.scalars(TextNormalizer.normalize(query))
        guard !q.isEmpty else { return [] }

        // Chuẩn hoá từng ký tự như TextNormalizer, nhớ mỗi scalar thuộc ký tự gốc nào.
        var normalized: [UInt32] = []
        var origin: [Int] = []
        normalized.reserveCapacity(min(text.utf8.count, maxCharacters))
        for (offset, ch) in text.prefix(maxCharacters).enumerated() {
            if ch.isWhitespace {
                if let last = normalized.last, last != FuzzyMatcher.space {
                    normalized.append(FuzzyMatcher.space)
                    origin.append(offset)
                }
                continue
            }
            if let ascii = ch.asciiValue {
                normalized.append(UInt32(ascii >= 65 && ascii <= 90 ? ascii + 32 : ascii))
                origin.append(offset)
            } else {
                for scalar in TextNormalizer.normalize(String(ch)).unicodeScalars {
                    normalized.append(scalar.value)
                    origin.append(offset)
                }
            }
        }

        let found: (match: FuzzyMatcher.Match, normalized: [UInt32], origin: [Int])
        if let match = FuzzyMatcher.match(q, in: normalized) {
            found = (match, normalized, origin)
        } else if let phonetic = PhoneticKey.build(String(text.prefix(maxCharacters))),
                  let match = FuzzyMatcher.match(q, in: phonetic.scalars) {
            // Khớp theo cách đọc: tô các chữ Hán/kana/Hangul tương ứng.
            found = (match, phonetic.scalars, phonetic.origin)
        } else {
            return []
        }
        var ranges: [Range<Int>] = []
        // Không tô khoảng trắng: "da nang" tô "Đà" và "Nẵng", không tô dấu cách giữa.
        let offsets = found.match.positions.filter { found.normalized[$0] != FuzzyMatcher.space }.map { found.origin[$0] }
        for offset in offsets {
            if let last = ranges.last, offset <= last.upperBound {
                ranges[ranges.count - 1] = last.lowerBound..<max(last.upperBound, offset + 1)
            } else {
                ranges.append(offset..<offset + 1)
            }
        }
        return ranges
    }
}

import Foundation

/// Khoá tìm kiếm thứ hai, theo cách đọc: chữ Hán và kana đổi sang chữ Latin (pinyin cho tiếng Trung,
/// romaji cho tiếng Nhật), âm tiết Hangul đổi thành phụ âm đầu. Nhờ đó gõ `beijing` ra “北京”,
/// `tokyo` ra “東京”, `ㅎㄱ` ra “한국” — giống gõ không dấu ra tiếng Việt.
/// Cách đọc lấy từ `CFStringTokenizer` của macOS, tách theo từ nên chữ đa âm đọc đúng theo ngữ cảnh.
public enum PhoneticKey {
    /// Chỉ xét chừng này ký tự đầu: tách từ tiếng Nhật/Trung chậm hơn nhiều so với chuẩn hoá thường.
    public static let maxCharacters = 2000

    /// Khoá lưu vào cột `phonetic_key`. `nil` nếu text không có chữ Hán, kana hay Hangul.
    public static func make(_ text: String) -> String? {
        guard let key = build(text) else { return nil }
        var result = ""
        result.unicodeScalars.append(contentsOf: key.scalars.compactMap { Unicode.Scalar($0) })
        return result
    }

    /// Các scalar của khoá, kèm offset `Character` trong text gốc của từng scalar (để tô sáng).
    struct Key {
        var scalars: [UInt32] = []
        var origin: [Int] = []

        mutating func append(_ scalar: UInt32, from offset: Int) {
            if scalar == FuzzyMatcher.space && (scalars.isEmpty || scalars.last == FuzzyMatcher.space) { return }
            scalars.append(scalar)
            origin.append(offset)
        }

        mutating func append(normalized text: String, from offset: Int) {
            for scalar in TextNormalizer.normalize(text).unicodeScalars { append(scalar.value, from: offset) }
        }
    }

    static func build(_ text: String) -> Key? {
        let chars = Array(text.prefix(maxCharacters))
        var hasHanOrKana = false, hasKana = false, hasHangul = false
        for scalar in chars.lazy.flatMap(\.unicodeScalars) {
            if isKana(scalar.value) { hasKana = true; hasHanOrKana = true }
            else if isHan(scalar.value) { hasHanOrKana = true }
            else if isHangulSyllable(scalar.value) { hasHangul = true }
        }
        guard hasHanOrKana || hasHangul else { return nil }

        let readings = hasHanOrKana ? transcriptions(of: chars, language: hasKana ? "ja" : "zh") : []
        var key = Key()
        var next = 0
        var i = 0
        while i < chars.count {
            if next < readings.count, readings[next].range.lowerBound == i {
                let reading = readings[next]
                next += 1
                appendReading(reading.latin, for: reading.range, of: chars, chinese: !hasKana, to: &key)
                i = reading.range.upperBound
                continue
            }
            let ch = chars[i]
            if ch.isWhitespace {
                key.append(FuzzyMatcher.space, from: i)
            } else if ch.unicodeScalars.count == 1, let v = ch.unicodeScalars.first?.value, isHangulSyllable(v) {
                // Phụ âm đầu dạng jamo tương thích — đúng thứ bàn phím Hàn gõ ra khi bấm riêng phụ âm.
                let initial = choseong[Int(v - 0xAC00) / 588]
                key.append(normalized: String(Unicode.Scalar(initial)!), from: i)
            } else {
                key.append(normalized: String(ch), from: i)
            }
            i += 1
        }
        if key.scalars.last == FuzzyMatcher.space {
            key.scalars.removeLast()
            key.origin.removeLast()
        }
        return key
    }

    /// Cách đọc Latin của từng từ có chữ Hán/kana, theo thứ tự, tính bằng offset `Character`.
    private static func transcriptions(of chars: [Character], language: String) -> [(range: Range<Int>, latin: String)] {
        let string = String(chars)
        let utf16Count = string.utf16.count
        // offset UTF-16 → offset Character (chỉ tại ranh giới ký tự; còn lại là -1).
        var charAt = [Int](repeating: -1, count: utf16Count + 1)
        var u = 0
        for (index, ch) in chars.enumerated() {
            charAt[u] = index
            u += ch.utf16.count
        }
        charAt[utf16Count] = chars.count

        let tokenizer = CFStringTokenizerCreate(
            nil, string as CFString, CFRange(location: 0, length: utf16Count),
            kCFStringTokenizerUnitWord, Locale(identifier: language) as CFLocale)
        var result: [(range: Range<Int>, latin: String)] = []
        let ns = string as NSString
        while !CFStringTokenizerAdvanceToNextToken(tokenizer).isEmpty {
            let r = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            guard r.location >= 0, r.location + r.length <= utf16Count else { continue }
            let start = charAt[r.location], end = charAt[r.location + r.length]
            guard start >= 0, end > start, start >= (result.last?.range.upperBound ?? 0) else { continue }
            let token = ns.substring(with: NSRange(location: r.location, length: r.length))
            guard token.unicodeScalars.contains(where: { isHan($0.value) || isKana($0.value) }),
                  let attribute = CFStringTokenizerCopyCurrentTokenAttribute(
                    tokenizer, kCFStringTokenizerAttributeLatinTranscription),
                  let latin = attribute as? String, !latin.isEmpty
            else { continue }
            result.append((start..<end, latin))
        }
        return result
    }

    /// Ghi cách đọc của một từ, bỏ khoảng trắng giữa các âm tiết (`běi jīng` → `beijing`) để gõ liền vẫn khớp.
    /// Số âm tiết bằng số chữ thì mỗi âm tiết gắn với chữ của nó (để tô đúng chữ); không thì chia đều theo độ dài.
    private static func appendReading(
        _ latin: String, for range: Range<Int>, of chars: [Character], chinese: Bool, to key: inout Key
    ) {
        var syllables = letters(of: latin)
        if chinese, syllables.count != range.count {
            // Bộ tách từ trả cả từ liền một khối (`beijing`). Pinyin từng chữ của ICU cho biết đoạn nào
            // thuộc chữ nào — chỉ dùng khi ghép lại trùng khớp, để giữ cách đọc theo ngữ cảnh của bộ tách từ.
            let perCharacter = NSMutableString(string: String(chars[range]))
            if CFStringTransform(perCharacter as CFMutableString, nil, kCFStringTransformMandarinLatin, false) {
                let candidate = letters(of: perCharacter as String)
                if candidate.count == range.count, candidate.flatMap({ $0 }) == syllables.flatMap({ $0 }) {
                    syllables = candidate
                }
            }
        }
        if syllables.count == range.count {
            for (offset, syllable) in zip(range, syllables) {
                for scalar in syllable { key.append(scalar.value, from: offset) }
            }
        } else {
            let letters = syllables.flatMap { $0 }
            for (k, scalar) in letters.enumerated() {
                key.append(scalar.value, from: range.lowerBound + k * range.count / letters.count)
            }
        }
    }

    /// Các âm tiết (tách theo khoảng trắng), mỗi âm tiết chỉ còn chữ Latin thường và số.
    private static func letters(of latin: String) -> [[Unicode.Scalar]] {
        latin.split(whereSeparator: \.isWhitespace).map {
            Array(TextNormalizer.normalize(String($0)).unicodeScalars.filter(isLatinLetterOrDigit))
        }
    }

    private static func isLatinLetterOrDigit(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x30...0x39, 0x61...0x7A: true
        default: false
        }
    }

    static func isHan(_ v: UInt32) -> Bool {
        switch v {
        case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF, 0x20000...0x323AF, 0x3005: true
        default: false
        }
    }

    static func isKana(_ v: UInt32) -> Bool {
        switch v {
        case 0x3041...0x309F, 0x30A0...0x30FF, 0x31F0...0x31FF, 0xFF66...0xFF9F: true
        default: false
        }
    }

    static func isHangulSyllable(_ v: UInt32) -> Bool { (0xAC00...0xD7A3).contains(v) }

    /// 19 phụ âm đầu của âm tiết Hangul, dạng jamo tương thích (ㄱ ㄲ ㄴ …).
    private static let choseong: [UInt32] = [
        0x3131, 0x3132, 0x3134, 0x3137, 0x3138, 0x3139, 0x3141, 0x3142, 0x3143, 0x3145,
        0x3146, 0x3147, 0x3148, 0x3149, 0x314A, 0x314B, 0x314C, 0x314D, 0x314E,
    ]
}

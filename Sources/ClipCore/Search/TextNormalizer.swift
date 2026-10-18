import Foundation

public enum TextNormalizer {
    /// Viết thường, bỏ dấu (kể cả `đ`), gộp khoảng trắng. Dùng cho cột `search_key` và chuỗi tìm kiếm.
    /// Thêm vài quy đổi để gõ không cần ký tự đặc biệt: `ß` → `ss`, `œ` → `oe`, `æ` → `ae`, `ø` → `o`,
    /// `ł` → `l`; hiragana coi như katakana (`ひらがな` khớp `ヒラガナ`).
    /// Đổi cách chuẩn hoá thì thêm migration gọi `Migrations.rebuildSearchKeys` cho dữ liệu cũ.
    public static func normalize(_ text: String) -> String {
        let folded = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .lowercased()
            // Ghép lại Hangul (nếu bị tách thành jamo) để mỗi âm tiết là một scalar.
            .precomposedStringWithCanonicalMapping
        var result = ""
        result.unicodeScalars.reserveCapacity(folded.unicodeScalars.count)
        var lastWasSpace = false
        for scalar in folded.unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                if !lastWasSpace && !result.isEmpty { result.append(" ") }
                lastWasSpace = true
                continue
            }
            lastWasSpace = false
            switch scalar.value {
            case 0x0111: result.append("d")                    // đ
            case 0x00DF: result.append("ss")                   // ß
            case 0x0153: result.append("oe")                   // œ
            case 0x00E6: result.append("ae")                   // æ
            case 0x00F8: result.append("o")                    // ø
            case 0x0142: result.append("l")                    // ł
            case 0x3041...0x3096, 0x309D, 0x309E:              // hiragana → katakana
                result.unicodeScalars.append(Unicode.Scalar(scalar.value + 0x60)!)
            default: result.unicodeScalars.append(scalar)
            }
        }
        if result.hasSuffix(" ") { result.removeLast() }
        return result
    }
}

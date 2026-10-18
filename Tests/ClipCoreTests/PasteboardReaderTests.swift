import Foundation
import Testing
@testable import ClipCore

@Suite struct PasteboardReaderTests {
    @Test(arguments: [
        ("https://github.com/anthropics/claude-code", true),
        ("  http://example.com/a?b=c  \n", true),
        ("github.com", false),
        ("ftp://example.com", false),
        ("xem https://example.com nhé", false),
        ("git commit -m \"fix\"", false),
    ])
    func linkClassification(text: String, isLink: Bool) {
        #expect(PasteboardReader.isLink(text) == isLink)
        #expect(textCapture(text).kind == (isLink ? .link : .text))
    }

    @Test func ignoresEmptyAndWhitespace() {
        #expect(PasteboardReader.read(from: FakePasteboard.text("   \n")) == nil)
        #expect(PasteboardReader.read(from: FakePasteboard(items: [:])) == nil)
    }

    @Test func hashIsStableAndKindAware() {
        #expect(textCapture("abc").contentHash == textCapture("abc").contentHash)
        #expect(textCapture("abc").contentHash != textCapture("abd").contentHash)
    }
}

@Suite struct TextNormalizerTests {
    @Test(arguments: [
        ("Báo cáo tuần 41", "bao cao tuan 41"),
        ("Đà Nẵng", "da nang"),
        ("  Nhiều   khoảng\ttrắng\n", "nhieu khoang trang"),
        ("ĐƯỜNG", "duong"),
        ("Straße", "strasse"),
        ("Cœur", "coeur"),
        ("Ærø Łódź", "aero lodz"),
        ("Ёлка", "елка"),
        ("ＡＢＣ１２３", "abc123"),
        ("한국어", "한국어"),
    ])
    func normalizes(input: String, expected: String) {
        #expect(TextNormalizer.normalize(input) == expected)
    }

    @Test func hiraganaMatchesKatakana() {
        #expect(TextNormalizer.normalize("ひらがな") == TextNormalizer.normalize("ヒラガナ"))
    }
}

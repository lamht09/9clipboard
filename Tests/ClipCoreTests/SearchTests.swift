import Foundation
import Testing
@testable import ClipCore

private func item(_ text: String, kind: ClipKind = .text, age: TimeInterval = 0) -> ClipItem {
    let date = Date(timeIntervalSince1970: 1_000_000 - age)
    return ClipItem(
        id: nil, kind: kind, contentHash: "\(kind)-\(text)", plainText: kind == .image ? nil : text,
        searchKey: kind == .image ? nil : TextNormalizer.normalize(text),
        sourceBundleID: nil, sourceAppName: nil, byteSize: text.utf8.count,
        imageWidth: nil, imageHeight: nil, createdAt: date, lastUsedAt: date,
        useCount: 0, pinboardID: nil, pinOrder: nil)
}

private func matches(_ query: String, _ text: String) -> FuzzyMatcher.Match? {
    FuzzyMatcher.match(
        FuzzyMatcher.scalars(TextNormalizer.normalize(query)),
        in: FuzzyMatcher.scalars(TextNormalizer.normalize(text)))
}

@Suite struct FuzzyMatcherTests {
    @Test(arguments: [
        ("bao cao", "Báo cáo tuần 41"),
        ("da nang", "Đà Nẵng"),
        ("Đà Nẵng", "da nang"),
        ("ĐƯỜNG", "đường Lê Lợi"),
        ("nguyen", "Nguyễn Văn A"),
        ("gtcmt", "git commit -m \"fix\""),
        ("baocao", "Báo cáo tuần 41"),
        ("CLAUDE", "github.com/anthropics/claude-code"),
    ])
    func vietnameseAndFuzzyMatches(query: String, text: String) {
        #expect(matches(query, text) != nil)
    }

    @Test(arguments: [
        ("xyz", "Báo cáo tuần 41"),
        ("cao bao", "Báo cáo"),
        ("commit git", "git commit"),
        // Các ký tự rải rác trong text dài không được tính là khớp.
        ("abc", "a" + String(repeating: "x", count: 100) + "b" + String(repeating: "y", count: 100) + "c"),
    ])
    func rejects(query: String, text: String) {
        #expect(matches(query, text) == nil)
    }

    @Test func substringBeatsSubsequence() throws {
        let substring = try #require(matches("cao", "bao cao"))
        let subsequence = try #require(matches("cao", "con chó ăn oản"))
        #expect(substring.score > subsequence.score)
    }

    @Test func wordStartBeatsMidWord() throws {
        let wordStart = try #require(matches("port", "import x; port 80"))
        let midWord = try #require(matches("port", "import"))
        #expect(wordStart.score > midWord.score)
        #expect(wordStart.positions == [10, 11, 12, 13])
    }

    @Test func picksTightestSubsequence() throws {
        let match = try #require(matches("gc", "g x x x x gc"))
        #expect(match.positions == [10, 11])
    }
}

@Suite struct SearchEngineTests {
    let items = [
        item("Báo cáo tuần 41", age: 10),
        item("https://github.com/anthropics/claude-code", kind: .link, age: 20),
        item("git commit -m \"fix\"", age: 30),
        item("", kind: .image, age: 40),
        item("Đà Nẵng mùa mưa", kind: .rich, age: 50),
        item("báo giá", age: 60),
    ]

    @Test func emptyQueryKeepsOrderAndFilters() {
        let engine = SearchEngine()
        #expect(engine.search(items, query: "  ", filter: .all).count == items.count)
        #expect(engine.search(items, query: "", filter: .text).map(\.item.plainText)
                == ["Báo cáo tuần 41", "git commit -m \"fix\"", "Đà Nẵng mùa mưa", "báo giá"])
        #expect(engine.search(items, query: "", filter: .link).count == 1)
        #expect(engine.search(items, query: "", filter: .image).count == 1)
    }

    @Test func findsWithoutDiacritics() {
        let engine = SearchEngine()
        #expect(engine.search(items, query: "da nang", filter: .all).map(\.item.plainText) == ["Đà Nẵng mùa mưa"])
        #expect(engine.search(items, query: "da nang", filter: .link).isEmpty)
    }

    @Test func ranksBetterMatchFirst() {
        let engine = SearchEngine()
        // "bao" khớp đầu text ở cả hai; mục mới hơn lên trước.
        #expect(engine.search(items, query: "bao", filter: .all).prefix(2).map(\.item.plainText) == ["Báo cáo tuần 41", "báo giá"])
        // Khớp liên tục ("bao gia") thắng subsequence dù mục cũ hơn.
        let results = engine.search(items, query: "bao gia", filter: .all)
        #expect(results.first?.item.plainText == "báo giá")
    }

    // Đo thời gian thật → runner CI dùng chung dao động, từng làm hỏng bản release. Chỉ đo trên máy.
    @Test(.disabled(if: ProcessInfo.processInfo.environment["CI"] != nil, "Đo hiệu năng không ổn định trên CI"))
    func searchesUnder10msFor2000Items() {
        let words = ["báo", "cáo", "tuần", "git", "commit", "Đà", "Nẵng", "https://", "github.com", "func",
                     "let", "var", "Nguyễn", "Văn", "hello", "world", "deploy", "staging", "SELECT", "FROM"]
        var rng = SystemRandomNumberGenerator()
        let many = (0..<2000).map { i in
            item((0..<Int.random(in: 5...60, using: &rng)).map { _ in words.randomElement(using: &rng)! }
                .joined(separator: " ") + " \(i)", age: Double(i))
        }
        // Mục tiêu 10ms là cho bản release; `make test` chạy bản debug chậm hơn nhiều.
        #if DEBUG
        let limit = Duration.milliseconds(120)
        #else
        let limit = Duration.milliseconds(10)
        #endif
        let engine = SearchEngine()
        _ = engine.search(many, query: "x", filter: .all)  // làm nóng cache key
        for query in ["bao cao", "gtcmt", "nguyen van", "zzzz", "d"] {
            let start = ContinuousClock.now
            _ = engine.search(many, query: query, filter: .all)
            let elapsed = ContinuousClock.now - start
            #expect(elapsed < limit, "\(query): \(elapsed)")
        }
    }
}

@Suite struct HighlighterTests {
    @Test func mapsBackToOriginalCharacters() {
        #expect(Highlighter.ranges(of: "da nang", in: "Ở Đà Nẵng") == [2..<4, 5..<9])
        #expect(Highlighter.ranges(of: "gtcmt", in: "git commit") == [0..<1, 2..<3, 4..<5, 6..<7, 9..<10])
    }

    @Test func collapsedWhitespaceStillMaps() {
        #expect(Highlighter.ranges(of: "a b", in: "x a   \n b") == [2..<3, 8..<9])
    }

    @Test func noMatchOrEmptyQuery() {
        #expect(Highlighter.ranges(of: "zz", in: "abc").isEmpty)
        #expect(Highlighter.ranges(of: "", in: "abc").isEmpty)
    }
}

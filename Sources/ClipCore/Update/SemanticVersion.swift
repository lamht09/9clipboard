import Foundation

/// Phiên bản dạng `1.2.3` hoặc `1.2.3-beta.4` (semver), so sánh theo quy tắc semver:
/// bản có hậu tố (beta, rc…) nhỏ hơn bản chính thức cùng số.
public struct SemanticVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
    public var major: Int
    public var minor: Int
    public var patch: Int
    /// Phần sau dấu "-", tách theo dấu chấm. Rỗng = bản chính thức.
    public var prerelease: [String]

    public var isPrerelease: Bool { !prerelease.isEmpty }

    /// Nhận cả tiền tố "v" (tên tag) và bỏ qua phần build sau dấu "+".
    public init?(_ string: String) {
        var s = Substring(string.trimmingCharacters(in: .whitespaces))
        if s.first == "v" || s.first == "V" { s = s.dropFirst() }
        if let plus = s.firstIndex(of: "+") { s = s[..<plus] }
        let core: Substring
        if let dash = s.firstIndex(of: "-") {
            core = s[..<dash]
            prerelease = s[s.index(after: dash)...].split(separator: ".", omittingEmptySubsequences: false).map(String.init)
            guard !prerelease.contains(where: \.isEmpty) else { return nil }
        } else {
            core = s
            prerelease = []
        }
        let numbers = core.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
        guard (1...3).contains(numbers.count), numbers.allSatisfy({ ($0 ?? -1) >= 0 }) else { return nil }
        major = numbers[0]!
        minor = numbers.count > 1 ? numbers[1]! : 0
        patch = numbers.count > 2 ? numbers[2]! : 0
    }

    public var description: String {
        let core = "\(major).\(minor).\(patch)"
        return prerelease.isEmpty ? core : core + "-" + prerelease.joined(separator: ".")
    }

    public static func < (a: Self, b: Self) -> Bool {
        if (a.major, a.minor, a.patch) != (b.major, b.minor, b.patch) {
            return (a.major, a.minor, a.patch) < (b.major, b.minor, b.patch)
        }
        switch (a.isPrerelease, b.isPrerelease) {
        case (false, false): return false
        case (true, false): return true
        case (false, true): return false
        case (true, true): break
        }
        // So từng phần: số so theo số, số nhỏ hơn chữ, chữ so theo bảng chữ; danh sách ngắn hơn nhỏ hơn.
        for (x, y) in zip(a.prerelease, b.prerelease) where x != y {
            switch (Int(x), Int(y)) {
            case let (i?, j?): return i < j
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return x < y
            }
        }
        return a.prerelease.count < b.prerelease.count
    }
}

import Foundation

/// Thông tin tác giả cho tab Giới thiệu trong Cài đặt.
enum About {
    static let author = "Lâm Hoàng"
    static let repositoryURL = URL(string: "https://github.com/lamht09/9clipboard")!
    static let repositoryLabel = "github.com/lamht09/9clipboard"

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    static var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "© 2026 \(author)"
    }
}

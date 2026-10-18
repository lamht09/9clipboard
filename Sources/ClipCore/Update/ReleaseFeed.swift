import Foundation

/// Danh sách bản phát hành từ GitHub (`GET /repos/{owner}/{repo}/releases`).
/// Chỉ giải mã các trường cần dùng.
public struct GitHubRelease: Decodable, Sendable, Equatable {
    public struct Asset: Decodable, Sendable, Equatable {
        public var name: String
        public var browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }

        public init(name: String, browserDownloadURL: URL) {
            self.name = name
            self.browserDownloadURL = browserDownloadURL
        }
    }

    public var tagName: String
    public var htmlURL: URL?
    public var draft: Bool
    public var prerelease: Bool
    public var assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case draft, prerelease, assets
    }

    public init(tagName: String, htmlURL: URL? = nil, draft: Bool = false, prerelease: Bool = false, assets: [Asset]) {
        self.tagName = tagName
        self.htmlURL = htmlURL
        self.draft = draft
        self.prerelease = prerelease
        self.assets = assets
    }
}

/// Bản cập nhật đã chọn: phiên bản, file zip để tải, trang ghi chú phát hành.
public struct AvailableUpdate: Sendable, Equatable {
    public var version: SemanticVersion
    public var downloadURL: URL
    public var releaseNotesURL: URL?
}

public enum ReleaseFeed {
    /// Tên file zip mà workflow release đính kèm vào mỗi bản phát hành.
    public static func assetName(for version: SemanticVersion) -> String {
        "9clipboard-\(version).zip"
    }

    public static func decode(_ data: Data) throws -> [GitHubRelease] {
        try JSONDecoder().decode([GitHubRelease].self, from: data)
    }

    /// Bản mới nhất cao hơn `current`, hoặc `nil` nếu đang dùng bản mới nhất.
    /// Bỏ qua bản nháp, bản thiếu file zip và — nếu không `includePrerelease` — bản beta.
    public static func newestUpdate(
        in releases: [GitHubRelease], current: SemanticVersion, includePrerelease: Bool
    ) -> AvailableUpdate? {
        releases
            .compactMap { release -> AvailableUpdate? in
                guard !release.draft, let version = SemanticVersion(release.tagName) else { return nil }
                guard includePrerelease || !(release.prerelease || version.isPrerelease) else { return nil }
                guard let asset = release.assets.first(where: { $0.name == assetName(for: version) }) else { return nil }
                return AvailableUpdate(version: version, downloadURL: asset.browserDownloadURL, releaseNotesURL: release.htmlURL)
            }
            .filter { $0.version > current }
            .max { $0.version < $1.version }
    }
}

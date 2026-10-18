import Foundation
import Testing
@testable import ClipCore

@Suite struct SemanticVersionTests {
    private func v(_ s: String) -> SemanticVersion { SemanticVersion(s)! }

    @Test func parses() {
        #expect(v("1.2.3") == SemanticVersion("v1.2.3"))
        #expect(v("1.2").patch == 0)
        #expect(v("1.0.0-beta.4").prerelease == ["beta", "4"])
        #expect(v("1.0.0+42") == v("1.0.0"))
        #expect(v("2.0.0-rc.1").description == "2.0.0-rc.1")
    }

    @Test(arguments: ["", "v", "1.x", "1.2.3.4", "-1.0.0", "1.0.0-", "1.0.0-beta..1"])
    func rejectsInvalid(_ s: String) {
        #expect(SemanticVersion(s) == nil)
    }

    @Test func ordersLikeSemver() {
        let ordered = [
            "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-beta", "1.0.0-beta.2", "1.0.0-beta.11",
            "1.0.0-rc.1", "1.0.0", "1.0.1", "1.1.0", "1.10.0", "2.0.0",
        ].map(v)
        #expect(ordered == ordered.shuffled().sorted())
        for (a, b) in zip(ordered, ordered.dropFirst()) {
            #expect(a < b)
        }
    }
}

@Suite struct ReleaseFeedTests {
    private func release(_ tag: String, prerelease: Bool = false, draft: Bool = false, asset: Bool = true) -> GitHubRelease {
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let name = "9clipboard-\(version).zip"
        return GitHubRelease(
            tagName: tag,
            htmlURL: URL(string: "https://github.com/lamht09/9clipboard/releases/tag/\(tag)"),
            draft: draft, prerelease: prerelease,
            assets: asset ? [.init(name: name, browserDownloadURL: URL(string: "https://example.com/\(name)")!)] : [])
    }

    @Test func picksNewestStable() {
        let releases = [release("v1.2.0-beta.1", prerelease: true), release("v1.1.0"), release("v1.0.0")]
        let update = ReleaseFeed.newestUpdate(in: releases, current: SemanticVersion("1.0.0")!, includePrerelease: false)
        #expect(update?.version == SemanticVersion("1.1.0"))
        #expect(update?.downloadURL.lastPathComponent == "9clipboard-1.1.0.zip")
    }

    @Test func nothingWhenUpToDate() {
        let releases = [release("v1.1.0"), release("v1.0.0")]
        #expect(ReleaseFeed.newestUpdate(in: releases, current: SemanticVersion("1.1.0")!, includePrerelease: true) == nil)
        #expect(ReleaseFeed.newestUpdate(in: releases, current: SemanticVersion("1.2.0")!, includePrerelease: true) == nil)
    }

    @Test func betasOnlyWhenOptedIn() {
        let releases = [release("v1.2.0-beta.2", prerelease: true), release("v1.1.0")]
        let current = SemanticVersion("1.0.0")!
        #expect(ReleaseFeed.newestUpdate(in: releases, current: current, includePrerelease: true)?.version
            == SemanticVersion("1.2.0-beta.2"))
        #expect(ReleaseFeed.newestUpdate(in: releases, current: current, includePrerelease: false)?.version
            == SemanticVersion("1.1.0"))
        // Tag có hậu tố nhưng quên đánh dấu pre-release trên GitHub vẫn coi là beta.
        let unmarked = [release("v1.2.0-rc.1"), release("v1.1.0")]
        #expect(ReleaseFeed.newestUpdate(in: unmarked, current: current, includePrerelease: false)?.version
            == SemanticVersion("1.1.0"))
    }

    @Test func stableReleaseSupersedesBeta() {
        let releases = [release("v1.2.0"), release("v1.2.0-beta.2", prerelease: true)]
        let update = ReleaseFeed.newestUpdate(in: releases, current: SemanticVersion("1.2.0-beta.1")!, includePrerelease: true)
        #expect(update?.version == SemanticVersion("1.2.0"))
        // Đang dùng beta mà tắt nhận beta: không báo beta mới hơn, cũng không "hạ cấp" về bản chính thức cũ hơn.
        let stableOnly = ReleaseFeed.newestUpdate(
            in: [release("v1.3.0-beta.1", prerelease: true), release("v1.1.0")],
            current: SemanticVersion("1.2.0-beta.1")!, includePrerelease: false)
        #expect(stableOnly == nil)
    }

    @Test func skipsDraftsAndReleasesWithoutZip() {
        let releases = [release("v1.3.0", draft: true), release("v1.2.0", asset: false), release("v1.1.0")]
        #expect(ReleaseFeed.newestUpdate(in: releases, current: SemanticVersion("1.0.0")!, includePrerelease: true)?.version
            == SemanticVersion("1.1.0"))
    }

    @Test func decodesGitHubJSON() throws {
        let json = """
        [{"tag_name":"v1.1.0","html_url":"https://github.com/lamht09/9clipboard/releases/tag/v1.1.0",
          "draft":false,"prerelease":false,"body":"notes",
          "assets":[{"name":"9clipboard-1.1.0.zip","size":1,
                     "browser_download_url":"https://github.com/lamht09/9clipboard/releases/download/v1.1.0/9clipboard-1.1.0.zip"}]}]
        """
        let releases = try ReleaseFeed.decode(Data(json.utf8))
        #expect(releases.count == 1)
        #expect(releases[0].assets[0].name == "9clipboard-1.1.0.zip")
    }
}

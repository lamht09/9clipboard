import ClipCore
import Foundation
import Security

/// Tải, kiểm tra và thay app bằng bản mới. Làm giống `install.sh`: file tải bằng URLSession không bị gắn
/// cờ quarantine nên Gatekeeper không chặn; bản mới phải ký cùng chứng chỉ với bản đang chạy nên
/// quyền Trợ năng (macOS lưu theo chữ ký) được giữ.
enum UpdateInstaller {
    enum Failure: LocalizedError {
        case download(Int)
        case badArchive
        case wrongBundle
        case signature

        var errorDescription: String? {
            switch self {
            case .download(let status):
                String(localized: "The download failed (HTTP \(status)).")
            case .badArchive:
                String(localized: "The downloaded file isn’t a valid 9clipboard archive.")
            case .wrongBundle:
                String(localized: "The download doesn’t contain the expected version of 9clipboard.")
            case .signature:
                String(localized: "The downloaded app isn’t signed with the 9clipboard certificate, so it wasn’t installed.")
            }
        }
    }

    /// Bản mới đã tải và kiểm tra xong, nằm trong `workDir` (cùng ổ đĩa với app để thay bằng rename).
    struct Staged: Sendable {
        var newApp: URL
        var workDir: URL
    }

    /// Tải và kiểm tra bản cập nhật. Chưa đụng tới app đang cài.
    static func download(_ update: AvailableUpdate, replacing appURL: URL) async throws -> Staged {
        let fm = FileManager.default
        let workDir = try fm.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: appURL, create: true)
        do {
            let (tempFile, response) = try await URLSession.shared.download(from: update.downloadURL)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw Failure.download(http.statusCode)
            }
            let zip = workDir.appendingPathComponent("update.zip")
            try fm.moveItem(at: tempFile, to: zip)

            let extracted = workDir.appendingPathComponent("new", isDirectory: true)
            try run("/usr/bin/ditto", "-x", "-k", zip.path, extracted.path)
            guard let newApp = try fm.contentsOfDirectory(at: extracted, includingPropertiesForKeys: nil)
                .first(where: { $0.pathExtension == "app" })
            else { throw Failure.badArchive }
            // Phòng khi file tải về vẫn bị gắn cờ; không có cờ thì xattr báo lỗi, bỏ qua.
            try? run("/usr/bin/xattr", "-dr", "com.apple.quarantine", newApp.path)

            try verify(newApp, expected: update.version)
            return Staged(newApp: newApp, workDir: workDir)
        } catch {
            try? fm.removeItem(at: workDir)
            throw error
        }
    }

    /// Bản mới phải đúng bundle ID, đúng phiên bản và thoả "designated requirement" của chính app đang chạy
    /// (cùng identifier + cùng chứng chỉ ký).
    static func verify(_ app: URL, expected: SemanticVersion) throws {
        guard let info = NSDictionary(contentsOf: app.appendingPathComponent("Contents/Info.plist")),
              info["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier,
              let short = info["CFBundleShortVersionString"] as? String,
              SemanticVersion(short) == expected
        else { throw Failure.wrongBundle }

        var newCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(app as CFURL, [], &newCode) == errSecSuccess, let newCode,
              let requirement = ownRequirement()
        else { throw Failure.signature }
        let flags = SecCSFlags(rawValue: UInt32(kSecCSCheckAllArchitectures | kSecCSStrictValidate | kSecCSCheckNestedCode))
        guard SecStaticCodeCheckValidity(newCode, flags, requirement) == errSecSuccess else {
            throw Failure.signature
        }
    }

    private static func ownRequirement() -> SecRequirement? {
        var me: SecCode?
        var meStatic: SecStaticCode?
        var requirement: SecRequirement?
        guard SecCodeCopySelf([], &me) == errSecSuccess, let me,
              SecCodeCopyStaticCode(me, [], &meStatic) == errSecSuccess, let meStatic,
              SecCodeCopyDesignatedRequirement(meStatic, [], &requirement) == errSecSuccess
        else { return nil }
        return requirement
    }

    /// Đổi chỗ app cũ và mới (hai lần rename, cùng ổ đĩa). Lỗi giữa chừng thì trả app cũ về chỗ cũ.
    /// Trả về thư mục chứa app cũ để xoá sau khi app đã thoát.
    static func install(_ staged: Staged, at appURL: URL) throws -> URL {
        let fm = FileManager.default
        let old = staged.workDir.appendingPathComponent("old", isDirectory: true)
        try fm.createDirectory(at: old, withIntermediateDirectories: true)
        let backup = old.appendingPathComponent(appURL.lastPathComponent)
        try fm.moveItem(at: appURL, to: backup)
        do {
            try fm.moveItem(at: staged.newApp, to: appURL)
        } catch {
            try? fm.moveItem(at: backup, to: appURL)
            throw error
        }
        return staged.workDir
    }

    private static func run(_ tool: String, _ arguments: String...) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw Failure.badArchive }
    }
}

import AppKit
import ClipCore
import SwiftUI

struct CardView: View {
    static let size: CGFloat = 220

    let item: ClipItem
    let index: Int
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
            footer
        }
        .frame(width: Self.size, height: Self.size)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        }
        .scaleEffect(isSelected ? 1.03 : 1)
        .animation(.easeOut(duration: 0.1), value: isSelected)
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(item.kind.label)
                .font(.system(size: 11, weight: .semibold))
            Spacer(minLength: 4)
            if let name = item.sourceAppName {
                Text(name)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .opacity(0.85)
            }
            if let icon = AppIconCache.icon(for: item.sourceBundleID) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(item.kind.color)
    }

    @ViewBuilder
    private var content: some View {
        let text = (item.plainText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        Text(String(text.prefix(600)))
            .font(CodeApps.isCodeApp(item.sourceBundleID)
                  ? .system(size: 11.5, design: .monospaced)
                  : .system(size: 12.5))
            .lineLimit(8)
            .foregroundStyle(item.kind == .link ? Color.accentColor : .primary)
    }

    private var footer: some View {
        HStack {
            Text(RelativeTime.string(for: item.lastUsedAt))
            if let w = item.imageWidth, let h = item.imageHeight {
                Text("\(w)×\(h)")
            }
            Spacer()
            if index < 9 {
                Text("⌘\(index + 1)")
            }
        }
        .font(.system(size: 10.5))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }
}

extension ClipKind {
    var label: String {
        switch self {
        case .text: "Text"
        case .rich: "Rich"
        case .image: "Ảnh"
        case .link: "Link"
        }
    }

    var color: Color {
        switch self {
        case .text: Color(red: 0.31, green: 0.56, blue: 0.97)
        case .rich: Color(red: 0.62, green: 0.40, blue: 0.90)
        case .image: Color(red: 0.20, green: 0.70, blue: 0.45)
        case .link: Color(red: 0.95, green: 0.55, blue: 0.20)
        }
    }
}

@MainActor
enum AppIconCache {
    private static var cache: [String: NSImage] = [:]

    static func icon(for bundleID: String?) -> NSImage? {
        guard let bundleID else { return nil }
        if let cached = cache[bundleID] { return cached }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache[bundleID] = icon
        return icon
    }
}

enum CodeApps {
    private static let bundleIDs: Set<String> = [
        "com.microsoft.VSCode", "com.apple.dt.Xcode", "com.apple.Terminal", "com.googlecode.iterm2",
        "dev.zed.Zed", "dev.warp.Warp-Stable", "com.todesktop.230313mzl4w4u92", "com.sublimetext.4",
        "com.mitchellh.ghostty", "net.kovidgoyal.kitty", "com.github.wez.wezterm",
    ]

    static func isCodeApp(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return bundleIDs.contains(bundleID) || bundleID.hasPrefix("com.jetbrains.")
    }
}

enum RelativeTime {
    static func string(for date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "vừa xong" }
        if seconds < 3600 { return "\(Int(seconds / 60)) phút" }
        if seconds < 86400 { return "\(Int(seconds / 3600)) giờ" }
        if Calendar.current.isDateInYesterday(date) { return "hôm qua" }
        if seconds < 7 * 86400 { return "\(Int(seconds / 86400)) ngày" }
        return date.formatted(.dateTime.day().month())
    }
}

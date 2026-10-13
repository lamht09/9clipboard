import AppKit
import ClipCore
import SwiftUI

struct CardView: View {
    static let size: CGFloat = 150

    let item: ClipItem
    let index: Int
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            footer
        }
        .frame(width: Self.size, height: Self.size)
        .background(VisualEffectBackground(cornerRadius: 10))
        .background(Color(nsColor: .textBackgroundColor).opacity(isSelected ? 0.6 : 0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
        }
        .scaleEffect(isSelected ? 1.03 : 1)
        .animation(.easeOut(duration: 0.1), value: isSelected)
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(item.kind.color)
                .frame(width: 6, height: 6)
            Text(item.kind.label)
                .font(.system(size: 10, weight: .semibold))
            Spacer(minLength: 4)
            if let icon = AppIconCache.icon(for: item.sourceBundleID) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 14, height: 14)
                    .help(item.sourceAppName ?? "")
            }
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .frame(height: 24)
    }

    @ViewBuilder
    private var content: some View {
        let text = (item.plainText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        Text(String(text.prefix(600)))
            .font(CodeApps.isCodeApp(item.sourceBundleID)
                  ? .system(size: 10.5, design: .monospaced)
                  : .system(size: 11.5))
            .lineLimit(6)
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
        .font(.system(size: 9.5))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }
}

/// Nền kính mờ (blend với nội dung phía sau cửa sổ), vì panel trong suốt.
struct VisualEffectBackground: NSViewRepresentable {
    var cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
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

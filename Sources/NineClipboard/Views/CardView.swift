import AppKit
import ClipCore
import SwiftUI

struct CardView: View {
    static let size = StripLayout.cardSize

    let item: ClipItem
    let index: Int
    let isSelected: Bool
    let previews: PreviewCache
    /// Chuỗi tìm đang áp dụng; phần khớp được tô sáng.
    var highlight = ""
    /// Bảng chứa thẻ (nếu đã ghim), để vẽ icon ghim theo màu bảng.
    var pinboard: Pinboard?
    /// Có thì thẻ đang chọn hiện các nút thao tác ở đầu thẻ.
    var viewModel: PanelViewModel?
    /// Nền đặc thay cho kính mờ, để `ImageRenderer` vẽ được (ảnh kéo-thả).
    var opaque = false

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
        .background {
            if opaque {
                Color(nsColor: .windowBackgroundColor)
            } else {
                VisualEffectBackground(cornerRadius: 10)
            }
        }
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
            if isSelected, let viewModel {
                // Thẻ đang chọn: thay icon app bằng các nút thao tác (icon ghim nằm trong đó).
                CardActionBar(viewModel: viewModel, item: item, pinboard: pinboard)
            } else {
                passiveBadges
            }
        }
        .foregroundStyle(.secondary)
        .padding(.leading, 8)
        .padding(.trailing, 5)
        .frame(height: 24)
    }

    @ViewBuilder
    private var passiveBadges: some View {
        Group {
            if item.isExpiring {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.orange)
                    .help("Password: deleted unless you keep it")
            }
            if let pinboard {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: pinboard.color))
                    .help(pinboard.name)
            }
            if let icon = AppIconCache.icon(for: item.sourceBundleID) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 14, height: 14)
                    .help(item.sourceAppName ?? "")
            }
        }
        .padding(.trailing, 3)
    }

    @ViewBuilder
    private var content: some View {
        if item.kind == .image {
            imageContent
        } else if let rich = previews.richText(for: item) {
            Text(previews.highlighted(rich, item: item, query: highlight) ?? rich).lineLimit(6)
        } else {
            plainText
                .font(CodeApps.isCodeApp(item.sourceBundleID)
                      ? .system(size: 10.5, design: .monospaced)
                      : .system(size: 11.5))
                .lineLimit(6)
                .foregroundStyle(item.kind == .link ? Color.accentColor : .primary)
        }
    }

    private var plainText: Text {
        if let highlighted = previews.highlightedPlainText(for: item, query: highlight) {
            return Text(highlighted)
        }
        let text = (item.plainText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return Text(String(text.prefix(600)))
    }

    @ViewBuilder
    private var imageContent: some View {
        Group {
            if let thumb = previews.thumbnail(for: item) {
                Image(nsImage: thumb)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            if let expiresAt = item.expiresAt {
                // Đếm ngược tới lúc tự xoá; tự cập nhật mỗi 15s khi panel đang mở.
                TimelineView(.periodic(from: .now, by: 15)) { context in
                    Text("deleted \(ExpiryText.string(until: expiresAt, now: context.date))")
                        .foregroundStyle(Color.orange)
                }
            } else {
                Text(RelativeTime.string(for: item.lastUsedAt))
            }
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
        case .text: String(localized: "Text")
        case .rich: String(localized: "Rich")
        case .image: String(localized: "Image")
        case .link: String(localized: "Link")
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

enum ExpiryText {
    /// "in 12 min" / "in 40 sec" / "now" ("sau 12 phút" / "sau 40 giây" / "ngay").
    static func string(until date: Date, now: Date = Date()) -> String {
        let seconds = date.timeIntervalSince(now)
        if seconds <= 0 { return String(localized: "now") }
        if seconds < 60 { return String(localized: "in \(Int(seconds)) sec") }
        return String(localized: "in \(Int((seconds / 60).rounded(.up))) min")
    }
}

enum RelativeTime {
    static func string(for date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return String(localized: "just now") }
        if seconds < 3600 { return String(localized: "\(Int(seconds / 60)) min") }
        if seconds < 86400 { return String(localized: "\(Int(seconds / 3600)) hr") }
        if Calendar.current.isDateInYesterday(date) { return String(localized: "yesterday") }
        if seconds < 7 * 86400 { return String(localized: "\(Int(seconds / 86400)) days") }
        return date.formatted(.dateTime.day().month())
    }
}

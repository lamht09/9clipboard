import AppKit
import ClipCore

/// Poll `NSPasteboard.general` mỗi 0.5s, phát hiện lần copy mới qua `changeCount`.
@MainActor
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private let privacy: PrivacyController
    private let onCapture: (Capture) -> Void
    private var timer: Timer?
    private var lastChangeCount: Int

    init(privacy: PrivacyController, onCapture: @escaping (Capture) -> Void) {
        self.privacy = privacy
        self.onCapture = onCapture
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        let types = pasteboard.typeIdentifiers
        if types.contains(UTI.selfMarker) { return }

        let app = NSWorkspace.shared.frontmostApplication
        guard privacy.shouldRecord(types: types, sourceBundleID: app?.bundleIdentifier) else { return }
        guard let capture = PasteboardReader.read(
            from: pasteboard,
            sourceBundleID: app?.bundleIdentifier,
            sourceAppName: app?.localizedName
        ) else { return }
        onCapture(capture)
    }
}

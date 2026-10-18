import AppKit
import ClipCore
import SwiftUI

/// Kéo thẻ ra khỏi panel rồi thả vào app khác: nội dung thẻ được thả đúng chỗ đó (ô nhập, Finder…).
/// Trong panel, kéo vẫn là cuộn / sắp xếp; chỉ khi con trỏ ra khỏi panel mới thành kéo-thả hệ thống.
@MainActor
final class CardDragOut: NSObject, NSDraggingSource {
    private let model: AppModel
    private let viewModel: PanelViewModel
    /// Thẻ dưới con trỏ lúc nhấn chuột, cùng các định dạng được nạp trước để lúc kéo ra có sẵn.
    private var pressed: ClipItem?
    private var representations: [Representation]?
    private var dragging: ClipItem?
    private static let fileStamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return formatter
    }()

    var onBegin: (() -> Void)?
    /// `dropped`: app đích đã nhận nội dung.
    var onEnd: ((ClipItem, _ dropped: Bool) -> Void)?

    init(model: AppModel, viewModel: PanelViewModel) {
        self.model = model
        self.viewModel = viewModel
    }

    /// Trả về true nếu đã nhận sự kiện (khi đó sự kiện không đi tiếp tới SwiftUI).
    func handle(_ event: NSEvent, in view: NSView) -> Bool {
        switch event.type {
        case .leftMouseDown:
            press(at: view.convert(event.locationInWindow, from: nil), in: view)
        case .leftMouseDragged:
            guard let item = pressed, dragging == nil,
                  !view.bounds.contains(view.convert(event.locationInWindow, from: nil)) else { return false }
            begin(item, event: event, in: view)
            return true
        case .leftMouseUp:
            pressed = nil
        default:
            break
        }
        return false
    }

    private func press(at point: NSPoint, in view: NSView) {
        pressed = nil
        representations = nil
        let y = view.isFlipped ? point.y : view.bounds.height - point.y
        let top = PanelLayout.barTop + PanelLayout.barHeight + StripLayout.verticalInset
        let x = point.x + viewModel.scrollOffset - StripLayout.inset
        guard y >= top, y <= top + StripLayout.cardSize, x >= 0 else { return }
        let index = Int(x / StripLayout.step)
        guard x - CGFloat(index) * StripLayout.step <= StripLayout.cardSize,
              viewModel.items.indices.contains(index) else { return }
        let item = viewModel.items[index]
        guard let id = item.id else { return }
        pressed = item
        Task {
            let reps = try? await model.store.representations(itemID: id)
            if pressed?.id == id { representations = reps }
        }
    }

    private func begin(_ item: ClipItem, event: NSEvent, in view: NSView) {
        pressed = nil
        dragging = item
        let entry = PasteService.pasteboardItem(item, representations: representations ?? [], blobLoader: model.store.blobs.load)
        if item.kind == .image, let url = imageFile(for: item) {
            // Có file thì Finder, Mail, trình duyệt… nhận ảnh như một file thật.
            entry.setString(url.absoluteString, forType: .fileURL)
        }
        let size = StripLayout.cardSize
        let point = view.convert(event.locationInWindow, from: nil)
        let dragItem = NSDraggingItem(pasteboardWriter: entry)
        dragItem.setDraggingFrame(NSRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size),
                                  contents: snapshot(of: item, in: view))
        viewModel.beginDragOut()
        let session = view.beginDraggingSession(with: [dragItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = false
        onBegin?()
    }

    /// Ghi ảnh ra file tạm có tên dễ đọc (file trong `blobs/` mang tên hash).
    private func imageFile(for item: ClipItem) -> URL? {
        guard let rep = representations?.first(where: { UTI.isImage($0.uti) }),
              let data = rep.data ?? rep.blobPath.flatMap(model.store.blobs.load) else { return nil }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("Drag", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let stamp = Self.fileStamp.string(from: item.createdAt)
        let url = dir.appendingPathComponent("\(String(localized: "Image")) \(stamp).\(rep.uti == UTI.tiff ? "tiff" : "png")")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    private func snapshot(of item: ClipItem, in view: NSView) -> NSImage? {
        let card = CardView(item: item, index: Int.max, isSelected: false, previews: viewModel.previews,
                            pinboard: viewModel.pinboard(for: item), opaque: true)
            .environment(\.colorScheme, view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light)
        let renderer = ImageRenderer(content: card)
        renderer.scale = view.window?.backingScaleFactor ?? 2
        return renderer.nsImage
    }

    nonisolated func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? .copy : []
    }

    nonisolated func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        let dropped = !operation.isEmpty
        MainActor.assumeIsolated {
            guard let item = dragging else { return }
            dragging = nil
            onEnd?(item, dropped)
        }
    }
}

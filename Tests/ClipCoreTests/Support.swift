import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import ClipCore

struct FakePasteboard: PasteboardSource {
    var changeCount = 1
    var items: [String: Data]
    var typeIdentifiers: [String] { Array(items.keys) }
    func data(forType uti: String) -> Data? { items[uti] }

    static func text(_ s: String, extra: [String: Data] = [:]) -> FakePasteboard {
        FakePasteboard(items: [UTI.plainText: Data(s.utf8)].merging(extra) { a, _ in a })
    }
}

func textCapture(_ s: String, app: String? = nil) -> Capture {
    PasteboardReader.read(from: FakePasteboard.text(s), sourceBundleID: app, sourceAppName: app)!
}

func makeStore() throws -> (ClipboardStore, AppDatabase) {
    let db = try AppDatabase.inMemory()
    return (ClipboardStore(database: db, blobs: try makeBlobStore()), db)
}

func makeBlobStore() throws -> BlobStore {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("9clipboard-tests-\(UUID().uuidString)", isDirectory: true)
    return try BlobStore(root: dir)
}

/// Ảnh thử `width`×`height` mã hoá theo `type` (PNG/TIFF). `seed` đổi màu để tạo ảnh khác nhau.
/// `alpha`: có kênh alpha; `opaque`: tô kín ảnh bằng màu đục (như ảnh chụp màn hình RGBA).
func makeImage(
    width: Int = 800, height: Int = 600, seed: CGFloat = 0.3,
    alpha: Bool = false, opaque: Bool = false, type: UTType = .png
) -> Data {
    let ctx = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: alpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)!
    if opaque {
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    ctx.setFillColor(CGColor(red: seed, green: 0.5, blue: 1 - seed, alpha: alpha && !opaque ? 0.5 : 1))
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height / 2))
    let out = NSMutableData()
    let dest = CGImageDestinationCreateWithData(out, type.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    return out as Data
}

func imageCapture(_ data: Data, uti: String = UTI.png) -> Capture {
    PasteboardReader.read(from: FakePasteboard(items: [uti: data]))!
}

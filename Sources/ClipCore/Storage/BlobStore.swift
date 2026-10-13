import Foundation

/// File ảnh nằm ngoài DB (DESIGN §4):
/// - `blobs/<2 ký tự đầu>/<content_hash>.png`: ảnh gốc
/// - `thumbs/<content_hash>.jpg|.png`: thumbnail cho thẻ
public struct BlobStore: Sendable {
    public enum Error: Swift.Error {
        case tooLarge(bytes: Int)
    }

    public static let thumbnailMaxPixel = 400

    public let root: URL
    private var blobsDir: URL { root.appendingPathComponent("blobs", isDirectory: true) }
    private var thumbsDir: URL { root.appendingPathComponent("thumbs", isDirectory: true) }

    public init(root: URL) throws {
        self.root = root
        try DataDirectory.ensureDirectory(root)
        try DataDirectory.ensureDirectory(blobsDir)
        try DataDirectory.ensureDirectory(thumbsDir)
    }

    public func url(forBlob relativePath: String) -> URL {
        blobsDir.appendingPathComponent(relativePath)
    }

    public func size(of relativePath: String) -> Int {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url(forBlob: relativePath).path)
        return (attrs?[.size] as? Int) ?? 0
    }

    public func load(_ relativePath: String) -> Data? {
        try? Data(contentsOf: url(forBlob: relativePath))
    }

    /// Ghi ảnh dưới dạng PNG (TIFF được đổi sang PNG). Trả về đường dẫn tương đối trong `blobs/`.
    /// Ném `tooLarge` nếu file PNG vượt `maxBytes`.
    public func storeImage(_ data: Data, uti: String, name: String, maxBytes: Int = .max) throws -> String {
        let png = uti == UTI.png ? data : try ImageCodec.pngData(from: data)
        guard png.count <= maxBytes else { throw Error.tooLarge(bytes: png.count) }
        let relativePath = "\(name.prefix(2))/\(name).png"
        let url = url(forBlob: relativePath)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try png.write(to: url, options: .atomic)
        return relativePath
    }

    /// Thumbnail đã tạo cho `name`, nếu có.
    public func thumbnailURL(for name: String) -> URL? {
        let fm = FileManager.default
        return ["jpg", "png"]
            .map { thumbsDir.appendingPathComponent("\(name).\($0)") }
            .first { fm.fileExists(atPath: $0.path) }
    }

    @discardableResult
    public func makeThumbnail(blobPath: String, name: String) throws -> URL {
        let (data, isPNG) = try ImageCodec.thumbnail(of: url(forBlob: blobPath), maxPixel: Self.thumbnailMaxPixel)
        let url = thumbsDir.appendingPathComponent("\(name).\(isPNG ? "png" : "jpg")")
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Xoá ảnh gốc kèm thumbnail. Tên thumbnail chính là tên file blob (content hash).
    public func delete(blobPaths: [String]) {
        let fm = FileManager.default
        for path in blobPaths {
            let blob = url(forBlob: path)
            try? fm.removeItem(at: blob)
            let name = blob.deletingPathExtension().lastPathComponent
            for ext in ["jpg", "png"] {
                try? fm.removeItem(at: thumbsDir.appendingPathComponent("\(name).\(ext)"))
            }
        }
    }
}

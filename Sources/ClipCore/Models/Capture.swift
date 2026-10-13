import Foundation

/// Kết quả đọc một lần copy từ pasteboard, trước khi lưu.
public struct Capture: Sendable, Hashable {
    public struct Item: Sendable, Hashable {
        public var uti: String
        public var data: Data
        public init(uti: String, data: Data) {
            self.uti = uti
            self.data = data
        }
    }

    public var kind: ClipKind
    public var plainText: String?
    public var representations: [Item]
    public var sourceBundleID: String?
    public var sourceAppName: String?
    public var imageWidth: Int?
    public var imageHeight: Int?

    public init(
        kind: ClipKind,
        plainText: String?,
        representations: [Item],
        sourceBundleID: String? = nil,
        sourceAppName: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil
    ) {
        self.kind = kind
        self.plainText = plainText
        self.representations = representations
        self.sourceBundleID = sourceBundleID
        self.sourceAppName = sourceAppName
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }

    public var byteSize: Int { representations.reduce(0) { $0 + $1.data.count } }

    /// Hash nội dung chính: text (nếu có) hoặc dữ liệu ảnh, kèm loại để rich và plain không gộp nhau.
    public var contentHash: String {
        let primary: Data
        if let plainText {
            primary = Data(plainText.utf8)
        } else if let image = representations.first(where: { $0.uti == UTI.png || $0.uti == UTI.tiff }) {
            primary = image.data
        } else {
            primary = representations.first?.data ?? Data()
        }
        return Hashing.sha256Hex(Data(kind.rawValue.utf8) + Data([0]) + primary)
    }
}

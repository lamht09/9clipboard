import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Đọc kích thước, đổi định dạng và tạo thumbnail ảnh bằng ImageIO (không cần AppKit, chạy được ở luồng nền).
public enum ImageCodec {
    public enum Error: Swift.Error {
        case undecodable
        case encodeFailed
    }

    /// Kích thước pixel, chỉ đọc header nên rẻ.
    public static func pixelSize(of data: Data) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0
        else { return nil }
        return (width, height)
    }

    /// Đổi ảnh bất kỳ (thường là TIFF) sang PNG.
    public static func pngData(from data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { throw Error.undecodable }
        return try encode(image, type: .png)
    }

    /// Thumbnail cạnh dài tối đa `maxPixel`. Ảnh thật sự có vùng trong suốt giữ PNG (JPEG sẽ biến chúng thành đen),
    /// còn lại dùng JPEG cho nhẹ.
    public static func thumbnail(of url: URL, maxPixel: Int) throws -> (data: Data, isPNG: Bool) {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { throw Error.undecodable }
        let transparent = hasTransparentPixels(thumb)
        return (try encode(thumb, type: transparent ? .png : .jpeg), transparent)
    }

    /// Ảnh chụp màn hình thường có kênh alpha dù đục hoàn toàn, nên phải quét pixel (thumbnail nhỏ nên rẻ).
    static func hasTransparentPixels(_ image: CGImage) -> Bool {
        guard ![.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo) else { return false }
        let width = image.width, height = image.height
        var alpha = [UInt8](repeating: 0, count: width * height)
        let drawn = alpha.withUnsafeMutableBytes { buffer -> Bool in
            guard let ctx = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)
            else { return false }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return !drawn || alpha.contains { $0 < 255 }
    }

    private static func encode(_ image: CGImage, type: UTType) throws -> Data {
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, type.identifier as CFString, 1, nil) else {
            throw Error.encodeFailed
        }
        let props: [CFString: Any] = type == .jpeg ? [kCGImageDestinationLossyCompressionQuality: 0.8] : [:]
        CGImageDestinationAddImage(dest, image, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { throw Error.encodeFailed }
        return out as Data
    }
}

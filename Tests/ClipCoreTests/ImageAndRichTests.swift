import Foundation
import GRDB
import Testing
@testable import ClipCore

@Suite struct RichCaptureTests {
    @Test func textWithRTFOrHTMLIsRich() {
        let rtf = Data(#"{\rtf1\ansi {\b Báo cáo} tuần 41}"#.utf8)
        let capture = PasteboardReader.read(from: FakePasteboard.text("Báo cáo tuần 41", extra: [
            UTI.rtf: rtf,
            UTI.html: Data("<b>Báo cáo</b> tuần 41".utf8),
        ]))!
        #expect(capture.kind == .rich)
        #expect(Set(capture.representations.map(\.uti)) == [UTI.plainText, UTI.rtf, UTI.html])
    }

    @Test func linkStaysLinkEvenWithHTML() {
        let capture = PasteboardReader.read(from: FakePasteboard.text("https://example.com", extra: [
            UTI.html: Data(#"<a href="https://example.com">https://example.com</a>"#.utf8),
        ]))!
        #expect(capture.kind == .link)
        #expect(capture.representations.count == 2)
    }

    @Test func rtfWithoutPlainTextDerivesText() {
        let capture = PasteboardReader.read(from: FakePasteboard(items: [UTI.rtf: Data(#"{\rtf1\ansi Xin chao}"#.utf8)]))
        #expect(capture?.kind == .rich)
        #expect(capture?.plainText == "Xin chao")
    }

    @Test func textWinsOverImage() {
        let capture = PasteboardReader.read(from: FakePasteboard.text("file.png", extra: [UTI.tiff: makeImage(type: .tiff)]))
        #expect(capture?.kind == .text)
    }
}

@Suite struct ImageCaptureTests {
    @Test func readsImageWithSize() {
        let capture = imageCapture(makeImage(width: 320, height: 200))
        #expect(capture.kind == .image)
        #expect(capture.plainText == nil)
        #expect(capture.imageWidth == 320 && capture.imageHeight == 200)
    }

    @Test func undecodableImageIsIgnored() {
        #expect(PasteboardReader.read(from: FakePasteboard(items: [UTI.png: Data("not an image".utf8)])) == nil)
    }

    @Test func imageHashIsStable() {
        let data = makeImage()
        #expect(imageCapture(data).contentHash == imageCapture(data).contentHash)
        #expect(imageCapture(data).contentHash != imageCapture(makeImage(seed: 0.9)).contentHash)
    }

    @Test func storesBlobAndThumbnailOutsideDB() async throws {
        let (store, _) = try makeStore()
        let item = try await store.insertOrBump(imageCapture(makeImage(width: 1600, height: 1000)), historyLimit: 500).item
        let reps = try await store.representations(itemID: item.id!)
        #expect(reps.count == 1)
        let rep = try #require(reps.first)
        #expect(rep.uti == UTI.png && rep.data == nil)

        let blobPath = try #require(rep.blobPath)
        #expect(blobPath == "\(item.contentHash.prefix(2))/\(item.contentHash).png")
        #expect(store.blobs.load(blobPath) != nil)

        let thumb = try #require(store.blobs.thumbnailURL(for: item.contentHash))
        #expect(thumb.pathExtension == "jpg")
        let size = try #require(ImageCodec.pixelSize(of: Data(contentsOf: thumb)))
        #expect(max(size.width, size.height) == BlobStore.thumbnailMaxPixel)
    }

    @Test func opaqueImageWithAlphaChannelGetsJPEGThumbnail() async throws {
        let (store, _) = try makeStore()
        let item = try await store.insertOrBump(imageCapture(makeImage(alpha: true, opaque: true)), historyLimit: 500).item
        #expect(store.blobs.thumbnailURL(for: item.contentHash)?.pathExtension == "jpg")
    }

    @Test func transparentImageGetsPNGThumbnail() async throws {
        let (store, _) = try makeStore()
        let item = try await store.insertOrBump(imageCapture(makeImage(alpha: true)), historyLimit: 500).item
        #expect(store.blobs.thumbnailURL(for: item.contentHash)?.pathExtension == "png")
    }

    @Test func tiffIsConvertedToPNG() async throws {
        let (store, _) = try makeStore()
        let item = try await store.insertOrBump(imageCapture(makeImage(type: .tiff), uti: UTI.tiff), historyLimit: 500).item
        let rep = try #require(try await store.representations(itemID: item.id!).first)
        let data = try #require(store.blobs.load(rep.blobPath!))
        #expect(data.starts(with: [0x89, 0x50, 0x4E, 0x47]))
        #expect(try await store.item(id: item.id!)?.byteSize == data.count)
    }

    @Test func oversizedImageIsRejectedAndNothingStored() async throws {
        let (store, _) = try makeStore()
        await #expect(throws: BlobStore.Error.self) {
            try await store.insertOrBump(imageCapture(makeImage()), historyLimit: 500, maxImageBytes: 100)
        }
        #expect(try await store.count() == 0)
    }

    @Test func deleteRemovesBlobAndThumbnail() async throws {
        let (store, _) = try makeStore()
        let item = try await store.insertOrBump(imageCapture(makeImage()), historyLimit: 500).item
        let blobPath = try #require(try await store.representations(itemID: item.id!).first?.blobPath)
        try await store.delete(id: item.id!)
        #expect(store.blobs.load(blobPath) == nil)
        #expect(store.blobs.thumbnailURL(for: item.contentHash) == nil)
    }

    @Test func retentionRemovesBlobFiles() async throws {
        let (store, _) = try makeStore()
        let t0 = Date(timeIntervalSince1970: 1000)
        let old = try await store.insertOrBump(imageCapture(makeImage(seed: 0.1)), historyLimit: 2, now: t0).item
        let blobPath = try #require(try await store.representations(itemID: old.id!).first?.blobPath)
        try await store.insertOrBump(textCapture("a"), historyLimit: 2, now: t0 + 1)
        try await store.insertOrBump(textCapture("b"), historyLimit: 2, now: t0 + 2)
        #expect(try await store.item(id: old.id!) == nil)
        #expect(store.blobs.load(blobPath) == nil)
        #expect(store.blobs.thumbnailURL(for: old.contentHash) == nil)
    }
}

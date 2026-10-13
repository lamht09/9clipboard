import Foundation
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
    return (ClipboardStore(database: db), db)
}

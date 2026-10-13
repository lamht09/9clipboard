import Foundation
import GRDB

/// Bọc `DatabaseQueue` đã chạy migration.
public struct AppDatabase: Sendable {
    public let queue: DatabaseQueue

    public init(queue: DatabaseQueue) throws {
        self.queue = queue
        try Migrations.migrator.migrate(queue)
    }

    /// Database trên đĩa tại `url`.
    public static func onDisk(at url: URL) throws -> AppDatabase {
        var config = Configuration()
        config.foreignKeysEnabled = true
        return try AppDatabase(queue: DatabaseQueue(path: url.path, configuration: config))
    }

    /// Database trong bộ nhớ, dùng cho test.
    public static func inMemory() throws -> AppDatabase {
        var config = Configuration()
        config.foreignKeysEnabled = true
        return try AppDatabase(queue: DatabaseQueue(configuration: config))
    }
}

public enum DataDirectory {
    /// `~/Library/Application Support/<folder>/`, tạo với quyền 0700 nếu chưa có.
    public static func url(folder: String = "9clipboard") throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = base.appendingPathComponent(folder, isDirectory: true)
        try ensureDirectory(dir)
        return dir
    }

    static func ensureDirectory(_ dir: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir.path)
    }
}

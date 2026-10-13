import Foundation
import GRDB

public struct Pinboard: Codable, Sendable, Identifiable, Hashable {
    public var id: Int64?
    public var name: String
    public var color: String
    public var sortOrder: Int

    public init(id: Int64? = nil, name: String, color: String, sortOrder: Int) {
        self.id = id
        self.name = name
        self.color = color
        self.sortOrder = sortOrder
    }

    enum CodingKeys: String, CodingKey {
        case id, name, color
        case sortOrder = "sort_order"
    }
}

extension Pinboard: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "pinboard"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

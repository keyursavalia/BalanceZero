import Foundation
import SwiftData

@Model
final class SavedItemList {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SavedItem.list)
    var items: [SavedItem] = []

    init(name: String, createdAt: Date = .now, items: [SavedItem] = []) {
        self.name = name
        self.createdAt = createdAt
        self.items = items
    }
}

@Model
final class SavedItem {
    var name: String
    var priceInCents: Int
    var createdAt: Date
    var list: SavedItemList?

    init(name: String, priceInCents: Int, createdAt: Date = .now, list: SavedItemList? = nil) {
        self.name = name
        self.priceInCents = priceInCents
        self.createdAt = createdAt
        self.list = list
    }
}


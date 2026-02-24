import XCTest
import SwiftData
@testable import BalanceZero

final class SavedItemListTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: SavedItemList.self, SavedItem.self, configurations: configuration)
    }

    @MainActor func testCreateListAndItemsPersist() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Groceries")
        let milk = SavedItem(name: "Milk", priceInCents: 345, list: list)
        let bread = SavedItem(name: "Bread", priceInCents: 299, list: list)
        list.items.append(contentsOf: [milk, bread])

        context.insert(list)
        try context.save()

        let descriptor = FetchDescriptor<SavedItemList>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.items.count, 2)
        let names = fetched.first?.items.map(\.name) ?? []
        XCTAssertEqual(Set(names), Set(["Milk", "Bread"]))
    }

    @MainActor func testDeletingListCascadesItems() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Snacks")
        let chips = SavedItem(name: "Chips", priceInCents: 199, list: list)
        list.items.append(chips)

        context.insert(list)
        try context.save()

        context.delete(list)
        try context.save()

        let listDescriptor = FetchDescriptor<SavedItemList>()
        let itemDescriptor = FetchDescriptor<SavedItem>()

        let lists = try context.fetch(listDescriptor)
        let items = try context.fetch(itemDescriptor)

        XCTAssertTrue(lists.isEmpty)
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor func testUpdateItemPrice() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Office")
        let pen = SavedItem(name: "Pen", priceInCents: 100, list: list)
        list.items.append(pen)

        context.insert(list)
        try context.save()

        pen.priceInCents = 150
        try context.save()

        let descriptor = FetchDescriptor<SavedItemList>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.first?.items.first?.priceInCents, 150)
    }
}


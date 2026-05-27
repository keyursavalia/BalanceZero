import Testing
import SwiftData
import Foundation
@testable import BalanceZero

// MARK: - Helpers

private func makeListContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: SavedItemList.self, SavedItem.self, configurations: config)
}

// MARK: - Saved Item List

@Suite("Saved Item List")
@MainActor
struct SavedItemListSuite {

    // MARK: Basic persistence

    @Test func createListWithItemsPersistsBoth() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Groceries")
        let milk = SavedItem(name: "Milk", priceInCents: 345, list: list)
        let bread = SavedItem(name: "Bread", priceInCents: 299, list: list)
        list.items.append(contentsOf: [milk, bread])
        context.insert(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.items.count == 2)
        let names = Set(fetched.first?.items.map(\.name) ?? [])
        #expect(names == Set(["Milk", "Bread"]))
    }

    @Test func deletingListCascadesAllItems() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Snacks")
        list.items.append(SavedItem(name: "Chips", priceInCents: 199, list: list))
        context.insert(list)
        try context.save()

        context.delete(list)
        try context.save()

        let lists = try context.fetch(FetchDescriptor<SavedItemList>())
        let items = try context.fetch(FetchDescriptor<SavedItem>())
        #expect(lists.isEmpty)
        #expect(items.isEmpty)
    }

    @Test func updatingItemPricePersists() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Office")
        let pen = SavedItem(name: "Pen", priceInCents: 100, list: list)
        list.items.append(pen)
        context.insert(list)
        try context.save()

        pen.priceInCents = 150
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.first?.items.first?.priceInCents == 150)
    }

    @Test func emptyListPersistsWithZeroItems() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Empty")
        context.insert(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.items.isEmpty == true)
    }

    @Test func itemMaintainsBackReferenceToParentListAfterFetch() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Backref Test")
        let item = SavedItem(name: "Water", priceInCents: 199, list: list)
        list.items.append(item)
        context.insert(list)
        try context.save()

        let fetchedLists = try context.fetch(FetchDescriptor<SavedItemList>())
        let fetchedList = fetchedLists[0]
        let fetchedItem = fetchedList.items[0]
        #expect(fetchedItem.list != nil)
        #expect(fetchedItem.list === fetchedList)
    }

    // MARK: Edge cases

    @Test func listWithEmptyNamePersists() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "")
        context.insert(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "")
    }

    @Test func listWithVeryLongNamePersists() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let longName = String(repeating: "A", count: 500)
        let list = SavedItemList(name: longName)
        context.insert(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.first?.name.count == 500)
    }

    @Test func twoListsWithSameNameBothPersist() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        context.insert(SavedItemList(name: "Duplicate"))
        context.insert(SavedItemList(name: "Duplicate"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.count == 2)
    }

    @Test func duplicateItemNamesInSameListBothPersist() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Dupes")
        list.items.append(SavedItem(name: "Apple", priceInCents: 99, list: list))
        list.items.append(SavedItem(name: "Apple", priceInCents: 149, list: list))
        context.insert(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.first?.items.count == 2)
    }

    @Test func itemWithZeroPricePersists() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Free Stuff")
        list.items.append(SavedItem(name: "Sample", priceInCents: 0, list: list))
        context.insert(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.first?.items.first?.priceInCents == 0)
    }

    @Test func oneHundredItemsInSingleListAllPersist() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "BigList")
        for i in 0..<100 {
            list.items.append(SavedItem(name: "Item\(i)", priceInCents: i * 10, list: list))
        }
        context.insert(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.first?.items.count == 100)
    }

    @Test func updatingListNamePersists() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Old Name")
        context.insert(list)
        try context.save()

        list.name = "New Name"
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.first?.name == "New Name")
    }

    @Test func insertingItemIntoExistingListPersists() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "List")
        context.insert(list)
        try context.save()

        let newItem = SavedItem(name: "Late Addition", priceInCents: 500, list: list)
        list.items.append(newItem)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedItemList>())
        #expect(fetched.first?.items.count == 1)
        #expect(fetched.first?.items.first?.name == "Late Addition")
    }

    @Test func deletingSpecificItemDoesNotDeleteList() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let list = SavedItemList(name: "Partial Delete")
        let item1 = SavedItem(name: "Keep", priceInCents: 100, list: list)
        let item2 = SavedItem(name: "Delete Me", priceInCents: 200, list: list)
        list.items.append(contentsOf: [item1, item2])
        context.insert(list)
        try context.save()

        context.delete(item2)
        try context.save()

        let fetchedLists = try context.fetch(FetchDescriptor<SavedItemList>())
        let fetchedItems = try context.fetch(FetchDescriptor<SavedItem>())
        #expect(fetchedLists.count == 1)
        #expect(fetchedItems.count == 1)
        #expect(fetchedItems.first?.name == "Keep")
    }

    @Test func listCreatedAtIsPopulatedOnInit() {
        let before = Date()
        let list = SavedItemList(name: "Test")
        let after = Date()
        #expect(list.createdAt >= before)
        #expect(list.createdAt <= after)
    }

    @Test func itemCreatedAtIsPopulatedOnInit() {
        let before = Date()
        let item = SavedItem(name: "Item", priceInCents: 100)
        let after = Date()
        #expect(item.createdAt >= before)
        #expect(item.createdAt <= after)
    }

    @Test func fetchDescriptorSortsByCreatedAtDescendingCorrectly() throws {
        let container = try makeListContainer()
        let context = container.mainContext

        let earlier = SavedItemList(name: "Earlier", createdAt: Date(timeIntervalSinceNow: -60))
        let later = SavedItemList(name: "Later", createdAt: Date(timeIntervalSinceNow: 0))
        context.insert(earlier)
        context.insert(later)
        try context.save()

        let descriptor = FetchDescriptor<SavedItemList>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let fetched = try context.fetch(descriptor)
        #expect(fetched[0].name == "Later")
        #expect(fetched[1].name == "Earlier")
    }
}

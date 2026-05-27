import Testing
import SwiftData
import Foundation
@testable import BalanceZero

// MARK: - Helpers

private func makeHistoryContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: SavedCalculation.self, SavedResultItem.self, configurations: config)
}

private func makeShoppingItem(name: String, cents: Int) -> ShoppingItem {
    ShoppingItem(name: name, priceInCents: cents)
}

private func makeSelectedItem(name: String, cents: Int, qty: Int = 1) -> SelectedItem {
    SelectedItem(item: makeShoppingItem(name: name, cents: cents), quantity: qty)
}

// MARK: - SavedCalculation Serialization

@Suite("Saved Calculation Serialization")
struct SavedCalculationSerializationSuite {

    @Test func fromFactoryPreservesBalanceInCents() {
        let result = OptimizationResult(
            balanceInCents: 1250,
            selectedItems: [],
            matchQuality: .perfect,
            allSelections: [[]]
        )
        let saved = SavedCalculation.from(result)
        #expect(saved.balanceInCents == 1250)
    }

    @Test func fromFactoryEncodesPerfectQuality() {
        let result = OptimizationResult(
            balanceInCents: 500,
            selectedItems: [],
            matchQuality: .perfect,
            allSelections: [[]]
        )
        let saved = SavedCalculation.from(result)
        #expect(saved.matchQualityKind == "perfect")
        #expect(saved.matchQualityRemainingCents == 0)
    }

    @Test func fromFactoryEncodesPartialQualityWithRemainingCents() {
        let result = OptimizationResult(
            balanceInCents: 500,
            selectedItems: [],
            matchQuality: .partial(remainingCents: 177),
            allSelections: [[]]
        )
        let saved = SavedCalculation.from(result)
        #expect(saved.matchQualityKind == "partial")
        #expect(saved.matchQualityRemainingCents == 177)
    }

    @Test func fromFactoryEncodesNoSolutionQuality() {
        let result = OptimizationResult(
            balanceInCents: 500,
            selectedItems: [],
            matchQuality: .noSolution,
            allSelections: []
        )
        let saved = SavedCalculation.from(result)
        #expect(saved.matchQualityKind == "noSolution")
    }

    @Test func fromFactoryCreatesOneResultItemPerSelectedItem() {
        let items = [
            makeSelectedItem(name: "Coffee", cents: 300),
            makeSelectedItem(name: "Snack", cents: 200, qty: 2)
        ]
        let result = OptimizationResult(
            balanceInCents: 700,
            selectedItems: items,
            matchQuality: .perfect,
            allSelections: [items]
        )
        let saved = SavedCalculation.from(result)
        #expect(saved.items.count == 2)
    }

    @Test func fromFactoryPreservesCardMetadata() {
        let result = OptimizationResult(
            balanceInCents: 1000,
            selectedItems: [],
            matchQuality: .perfect,
            allSelections: [[]]
        )
        let saved = SavedCalculation.from(
            result,
            cardName: "Daily Driver",
            cardDesignRawValue: "midnight",
            cardCustomColorHex: "ff0000"
        )
        #expect(saved.cardName == "Daily Driver")
        #expect(saved.cardDesignRawValue == "midnight")
        #expect(saved.cardCustomColorHex == "ff0000")
    }

    @Test func matchQualityComputedPropertyReturnsPerfectForPerfectKind() {
        let calc = SavedCalculation(balanceInCents: 500, matchQualityKind: "perfect")
        #expect(calc.matchQuality == .perfect)
    }

    @Test func matchQualityComputedPropertyReturnsPartialWithRemainingCents() {
        let calc = SavedCalculation(
            balanceInCents: 500,
            matchQualityKind: "partial",
            matchQualityRemainingCents: 177
        )
        #expect(calc.matchQuality == .partial(remainingCents: 177))
    }

    @Test func matchQualityComputedPropertyReturnsNoSolutionForNoSolutionKind() {
        let calc = SavedCalculation(balanceInCents: 500, matchQualityKind: "noSolution")
        #expect(calc.matchQuality == .noSolution)
    }

    @Test func matchQualityComputedPropertyFallsBackToNoSolutionForUnknownKind() {
        let calc = SavedCalculation(balanceInCents: 500, matchQualityKind: "COMPLETELY_UNKNOWN")
        #expect(calc.matchQuality == .noSolution)
    }

    @Test func optimizationResultReconstructsSelectedItemsCorrectly() {
        let item = makeSelectedItem(name: "Coffee", cents: 300, qty: 2)
        let result = OptimizationResult(
            balanceInCents: 600,
            selectedItems: [item],
            matchQuality: .perfect,
            allSelections: [[item]]
        )
        let saved = SavedCalculation.from(result)
        let reconstructed = saved.optimizationResult

        #expect(reconstructed.balanceInCents == 600)
        #expect(reconstructed.selectedItems.first?.item.name == "Coffee")
        #expect(reconstructed.selectedItems.first?.item.priceInCents == 300)
        #expect(reconstructed.selectedItems.first?.quantity == 2)
    }

    @Test func optimizationResultReconstructsAllSelectionsFromEncodedData() {
        let a = makeSelectedItem(name: "A", cents: 300)
        let b = makeSelectedItem(name: "B", cents: 200)
        let result = OptimizationResult(
            balanceInCents: 500,
            selectedItems: [a],
            matchQuality: .perfect,
            allSelections: [[a], [b]]
        )
        let saved = SavedCalculation.from(result)
        let reconstructed = saved.optimizationResult

        #expect(reconstructed.allSelections.count == 2)
        #expect(reconstructed.allSelections[0].first?.item.name == "A")
        #expect(reconstructed.allSelections[1].first?.item.name == "B")
    }

    @Test func optimizationResultFallsBackToSelectedItemsWhenAllSelectionsDataIsNil() {
        let calc = SavedCalculation(
            balanceInCents: 500,
            matchQualityKind: "perfect",
            allSelectionsData: nil
        )
        let item = SavedResultItem(name: "Item", priceInCents: 500, quantity: 1, calculation: calc)
        calc.items.append(item)

        let reconstructed = calc.optimizationResult
        #expect(reconstructed.allSelections.count == 1)
        #expect(reconstructed.allSelections[0].first?.item.name == "Item")
    }

    @Test func optimizationResultFallsBackToSelectedItemsWhenAllSelectionsDataIsCorrupted() {
        let corruptedData = Data([0xFF, 0xFE, 0x00, 0x01])
        let calc = SavedCalculation(
            balanceInCents: 500,
            matchQualityKind: "perfect",
            allSelectionsData: corruptedData
        )
        let item = SavedResultItem(name: "Coffee", priceInCents: 300, quantity: 1, calculation: calc)
        calc.items.append(item)

        let reconstructed = calc.optimizationResult
        // Corrupted JSON → decodes as [] → falls back to [selectedItems]
        #expect(reconstructed.allSelections.count == 1)
        #expect(reconstructed.allSelections[0].first?.item.name == "Coffee")
    }

    @Test func fromFactoryWithEmptySelectedItemsProducesEmptyResultItems() {
        let result = OptimizationResult(
            balanceInCents: 500,
            selectedItems: [],
            matchQuality: .noSolution,
            allSelections: []
        )
        let saved = SavedCalculation.from(result)
        #expect(saved.items.isEmpty)
    }

    @Test func allSelectionsRoundTripThroughEncodingAndDecoding() {
        let fifty = (0..<50).map { makeSelectedItem(name: "Item\($0)", cents: 100, qty: $0 + 1) }
        let result = OptimizationResult(
            balanceInCents: 999999,
            selectedItems: fifty,
            matchQuality: .perfect,
            allSelections: [fifty, Array(fifty.reversed())]
        )
        let saved = SavedCalculation.from(result)
        let reconstructed = saved.optimizationResult

        #expect(reconstructed.allSelections.count == 2)
        #expect(reconstructed.allSelections[0].count == 50)
        #expect(reconstructed.allSelections[1].count == 50)
    }
}

// MARK: - SavedCalculation Persistence

@Suite("Saved Calculation Persistence")
@MainActor
struct SavedCalculationPersistenceSuite {

    @Test func savedCalculationPersistsAndFetchesBack() throws {
        let container = try makeHistoryContainer()
        let context = container.mainContext

        let result = OptimizationResult(
            balanceInCents: 1000,
            selectedItems: [makeSelectedItem(name: "Chips", cents: 199, qty: 3)],
            matchQuality: .partial(remainingCents: 403),
            allSelections: [[makeSelectedItem(name: "Chips", cents: 199, qty: 3)]]
        )
        let saved = SavedCalculation.from(result, cardName: "My Card")
        context.insert(saved)
        try context.save()

        let descriptor = FetchDescriptor<SavedCalculation>()
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.balanceInCents == 1000)
        #expect(fetched.first?.matchQualityKind == "partial")
        #expect(fetched.first?.matchQualityRemainingCents == 403)
        #expect(fetched.first?.cardName == "My Card")
    }

    @Test func savedCalculationPersistsSavedResultItems() throws {
        let container = try makeHistoryContainer()
        let context = container.mainContext

        let items = [
            makeSelectedItem(name: "Coffee", cents: 300),
            makeSelectedItem(name: "Snack", cents: 200)
        ]
        let result = OptimizationResult(
            balanceInCents: 500,
            selectedItems: items,
            matchQuality: .perfect,
            allSelections: [items]
        )
        let saved = SavedCalculation.from(result)
        context.insert(saved)
        try context.save()

        let descriptor = FetchDescriptor<SavedCalculation>()
        let fetched = try context.fetch(descriptor).first
        #expect(fetched?.items.count == 2)
    }

    @Test func deletingCalculationCascadesResultItems() throws {
        let container = try makeHistoryContainer()
        let context = container.mainContext

        let result = OptimizationResult(
            balanceInCents: 500,
            selectedItems: [makeSelectedItem(name: "Item", cents: 500)],
            matchQuality: .perfect,
            allSelections: [[makeSelectedItem(name: "Item", cents: 500)]]
        )
        let saved = SavedCalculation.from(result)
        context.insert(saved)
        try context.save()

        context.delete(saved)
        try context.save()

        let calculations = try context.fetch(FetchDescriptor<SavedCalculation>())
        let resultItems = try context.fetch(FetchDescriptor<SavedResultItem>())
        #expect(calculations.isEmpty)
        #expect(resultItems.isEmpty)
    }

    @Test func savedResultItemBackReferenceToCalculationIsIntact() throws {
        let container = try makeHistoryContainer()
        let context = container.mainContext

        let result = OptimizationResult(
            balanceInCents: 300,
            selectedItems: [makeSelectedItem(name: "Coffee", cents: 300)],
            matchQuality: .perfect,
            allSelections: [[makeSelectedItem(name: "Coffee", cents: 300)]]
        )
        let saved = SavedCalculation.from(result)
        context.insert(saved)
        try context.save()

        let descriptor = FetchDescriptor<SavedResultItem>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.first?.calculation != nil)
        #expect(fetched.first?.calculation?.balanceInCents == 300)
    }

    @Test func cardMetadataSurvivesAfterSavingWithoutCardModel() throws {
        // Verify metadata is stored as plain strings, independent of any Card object
        let container = try makeHistoryContainer()
        let context = container.mainContext

        let result = OptimizationResult(
            balanceInCents: 2000,
            selectedItems: [],
            matchQuality: .noSolution,
            allSelections: []
        )
        let saved = SavedCalculation.from(
            result,
            cardName: "Deleted Card",
            cardDesignRawValue: "starbucks",
            cardCustomColorHex: "1b5e20"
        )
        context.insert(saved)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedCalculation>()).first
        #expect(fetched?.cardName == "Deleted Card")
        #expect(fetched?.cardDesignRawValue == "starbucks")
        #expect(fetched?.cardCustomColorHex == "1b5e20")
    }
}

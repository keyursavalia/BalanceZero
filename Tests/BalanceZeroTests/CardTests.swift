import Testing
import SwiftData
import Foundation
@testable import BalanceZero

// MARK: - Helpers

private func makeCardContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Card.self, CardTransaction.self, configurations: config)
}

// MARK: - Card Model

@Suite("Card Model")
@MainActor
struct CardModelSuite {

    @Test func currentBalanceEqualsInitialBalanceWithNoTransactions() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Test", initialBalanceInCents: 5000)
        context.insert(card)
        try context.save()
        #expect(card.currentBalanceInCents == 5000)
    }

    @Test func currentBalanceDecreasesWithEachTransaction() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Test", initialBalanceInCents: 5000)
        let tx = CardTransaction(note: "Coffee", amountInCents: 300, card: card)
        card.transactions.append(tx)
        context.insert(card)
        try context.save()
        #expect(card.totalSpentInCents == 300)
        #expect(card.currentBalanceInCents == 4700)
    }

    @Test func currentBalanceWithMultipleTransactions() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Test", initialBalanceInCents: 10000)
        card.transactions.append(CardTransaction(note: "A", amountInCents: 1500, card: card))
        card.transactions.append(CardTransaction(note: "B", amountInCents: 2500, card: card))
        card.transactions.append(CardTransaction(note: "C", amountInCents: 1000, card: card))
        context.insert(card)
        try context.save()
        #expect(card.totalSpentInCents == 5000)
        #expect(card.currentBalanceInCents == 5000)
    }

    @Test func currentBalanceGoesNegativeWhenTransactionsExceedInitial() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Test", initialBalanceInCents: 1000)
        card.transactions.append(CardTransaction(note: "Overcharge", amountInCents: 1500, card: card))
        context.insert(card)
        try context.save()
        #expect(card.currentBalanceInCents == -500)
    }

    @Test func clampedCurrentBalanceIsZeroWhenTransactionsExceedInitial() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Test", initialBalanceInCents: 1000)
        card.transactions.append(CardTransaction(note: "Overcharge", amountInCents: 1500, card: card))
        context.insert(card)
        try context.save()
        #expect(card.clampedCurrentBalance == 0)
    }

    @Test func clampedCurrentBalanceEqualsCurrentBalanceWhenPositive() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Test", initialBalanceInCents: 5000)
        card.transactions.append(CardTransaction(note: "Coffee", amountInCents: 300, card: card))
        context.insert(card)
        try context.save()
        #expect(card.clampedCurrentBalance == card.currentBalanceInCents)
        #expect(card.clampedCurrentBalance == 4700)
    }

    @Test func clampedCurrentBalanceIsZeroWhenTransactionsDrainBalanceExactly() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Test", initialBalanceInCents: 5000)
        card.transactions.append(CardTransaction(note: "Exact", amountInCents: 5000, card: card))
        context.insert(card)
        try context.save()
        #expect(card.currentBalanceInCents == 0)
        #expect(card.clampedCurrentBalance == 0)
    }

    @Test func designPropertyRoundTripsThroughRawValue() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        for design in CardDesign.allCases {
            let card = Card(name: "Test", initialBalanceInCents: 1000, design: design)
            context.insert(card)
        }
        try context.save()

        let descriptor = FetchDescriptor<Card>()
        let fetched = try context.fetch(descriptor)
        let designs = Set(fetched.map(\.design))
        #expect(designs == Set(CardDesign.allCases))
    }

    @Test func invalidDesignRawValueFallsBackToClassic() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Test", initialBalanceInCents: 1000)
        card.designRawValue = "completely_invalid_value"
        context.insert(card)
        try context.save()
        #expect(card.design == .classic)
    }

    @Test func oneHundredTransactionsComputeBalanceCorrectly() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Stress", initialBalanceInCents: 100000)
        for i in 0..<100 {
            card.transactions.append(CardTransaction(note: "T\(i)", amountInCents: 100, card: card))
        }
        context.insert(card)
        try context.save()
        #expect(card.totalSpentInCents == 10000)
        #expect(card.currentBalanceInCents == 90000)
    }

    @Test func twoCardsWithSameNameBothPersist() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card1 = Card(name: "Duplicate", initialBalanceInCents: 1000)
        let card2 = Card(name: "Duplicate", initialBalanceInCents: 2000)
        context.insert(card1)
        context.insert(card2)
        try context.save()

        let descriptor = FetchDescriptor<Card>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 2)
    }

    @Test func deletingCardCascadesAllTransactions() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "ToDelete", initialBalanceInCents: 5000)
        card.transactions.append(CardTransaction(note: "A", amountInCents: 100, card: card))
        card.transactions.append(CardTransaction(note: "B", amountInCents: 200, card: card))
        context.insert(card)
        try context.save()

        context.delete(card)
        try context.save()

        let cards = try context.fetch(FetchDescriptor<Card>())
        let transactions = try context.fetch(FetchDescriptor<CardTransaction>())
        #expect(cards.isEmpty)
        #expect(transactions.isEmpty)
    }
}

// MARK: - Card Transactions

@Suite("Card Transactions")
@MainActor
struct CardTransactionSuite {

    @Test func transactionPersistsNoteAndAmount() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Card", initialBalanceInCents: 5000)
        let tx = CardTransaction(note: "Lunch", amountInCents: 1250, card: card)
        card.transactions.append(tx)
        context.insert(card)
        try context.save()

        let descriptor = FetchDescriptor<CardTransaction>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.first?.note == "Lunch")
        #expect(fetched.first?.amountInCents == 1250)
    }

    @Test func transactionBackReferencesToCardAreIntact() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Card", initialBalanceInCents: 5000)
        let tx = CardTransaction(note: "Coffee", amountInCents: 400, card: card)
        card.transactions.append(tx)
        context.insert(card)
        try context.save()

        let descriptor = FetchDescriptor<CardTransaction>()
        let fetchedTx = try context.fetch(descriptor).first
        #expect(fetchedTx?.card?.name == "Card")
    }

    @Test func transactionWithZeroAmountPersists() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Card", initialBalanceInCents: 5000)
        let tx = CardTransaction(note: "Free", amountInCents: 0, card: card)
        card.transactions.append(tx)
        context.insert(card)
        try context.save()

        let descriptor = FetchDescriptor<CardTransaction>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.first?.amountInCents == 0)
        #expect(card.currentBalanceInCents == 5000)
    }

    @Test func transactionCreatedAtIsPopulatedOnInit() {
        let before = Date()
        let tx = CardTransaction(note: "Test", amountInCents: 100)
        let after = Date()
        #expect(tx.createdAt >= before)
        #expect(tx.createdAt <= after)
    }

    @Test func deletingIndividualTransactionDoesNotDeleteCard() throws {
        let container = try makeCardContainer()
        let context = container.mainContext
        let card = Card(name: "Card", initialBalanceInCents: 5000)
        let tx = CardTransaction(note: "Coffee", amountInCents: 300, card: card)
        card.transactions.append(tx)
        context.insert(card)
        try context.save()

        context.delete(tx)
        try context.save()

        let cards = try context.fetch(FetchDescriptor<Card>())
        let transactions = try context.fetch(FetchDescriptor<CardTransaction>())
        #expect(cards.count == 1)
        #expect(transactions.isEmpty)
        #expect(cards.first?.currentBalanceInCents == 5000)
    }
}

// MARK: - Card Design

@Suite("Card Design")
struct CardDesignSuite {

    @Test func allSevenDesignCasesExist() {
        #expect(CardDesign.allCases.count == 7)
    }

    @Test func allDesignCasesHaveUniqueRawValues() {
        let rawValues = CardDesign.allCases.map(\.rawValue)
        #expect(Set(rawValues).count == rawValues.count)
    }

    @Test func allDesignCasesHaveNonEmptyDisplayNames() {
        for design in CardDesign.allCases {
            #expect(!design.displayName.isEmpty, "Design \(design.rawValue) has empty displayName")
        }
    }

    @Test func allDesignCasesHaveTwoGradientColors() {
        for design in CardDesign.allCases {
            #expect(design.gradientColors.count == 2, "Design \(design.rawValue) does not have exactly 2 gradient colors")
        }
    }

    @Test func allDesignCasesHaveNonEmptySymbolName() {
        for design in CardDesign.allCases {
            #expect(!design.symbolName.isEmpty, "Design \(design.rawValue) has empty symbolName")
        }
    }

    @Test func invalidRawValueReturnsNilFromInit() {
        let design = CardDesign(rawValue: "not_a_real_design")
        #expect(design == nil)
    }

    @Test func customDesignHasCustomRawValue() {
        #expect(CardDesign.custom.rawValue == "custom")
    }

    @Test func cardDesignInitFromRawValueRoundTrips() {
        for design in CardDesign.allCases {
            let reconstructed = CardDesign(rawValue: design.rawValue)
            #expect(reconstructed == design)
        }
    }
}

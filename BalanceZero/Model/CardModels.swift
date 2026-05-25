import Foundation
import SwiftData

@Model
final class Card {
    var name: String
    var initialBalanceInCents: Int
    var designRawValue: String
    var createdAt: Date
    var customColorHex: String = ""
    var customCompanyName: String = ""
    @Relationship(deleteRule: .cascade, inverse: \CardTransaction.card)
    var transactions: [CardTransaction] = []

    init(
        name: String,
        initialBalanceInCents: Int,
        design: CardDesign = .classic,
        customColorHex: String = "",
        customCompanyName: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.initialBalanceInCents = initialBalanceInCents
        self.designRawValue = design.rawValue
        self.customColorHex = customColorHex
        self.customCompanyName = customCompanyName
        self.createdAt = createdAt
    }

    var design: CardDesign {
        get { CardDesign(rawValue: designRawValue) ?? .classic }
        set { designRawValue = newValue.rawValue }
    }

    var totalSpentInCents: Int {
        transactions.reduce(0) { $0 + $1.amountInCents }
    }

    var currentBalanceInCents: Int {
        initialBalanceInCents - totalSpentInCents
    }
}

@Model
final class CardTransaction {
    var note: String
    var amountInCents: Int
    var createdAt: Date
    var card: Card?

    init(note: String, amountInCents: Int, createdAt: Date = .now, card: Card? = nil) {
        self.note = note
        self.amountInCents = amountInCents
        self.createdAt = createdAt
        self.card = card
    }
}

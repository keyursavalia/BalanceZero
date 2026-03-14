import Foundation
import SwiftData

@Model
final class SavedCalculation {
    var balanceInCents: Int
    var matchQualityKind: String // "perfect" | "partial" | "noSolution"
    var matchQualityRemainingCents: Int // only used when kind == "partial"
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SavedResultItem.calculation)
    var items: [SavedResultItem] = []

    init(
        balanceInCents: Int,
        matchQualityKind: String,
        matchQualityRemainingCents: Int = 0,
        createdAt: Date = .now
    ) {
        self.balanceInCents = balanceInCents
        self.matchQualityKind = matchQualityKind
        self.matchQualityRemainingCents = matchQualityRemainingCents
        self.createdAt = createdAt
    }

    var matchQuality: MatchQuality {
        switch matchQualityKind {
        case "perfect": return .perfect
        case "partial": return .partial(remainingCents: matchQualityRemainingCents)
        default: return .noSolution
        }
    }

    var optimizationResult: OptimizationResult {
        let selectedItems = items.map { sel in
            let item = ShoppingItem(
                name: sel.name,
                priceInCents: sel.priceInCents,
                mandatoryQuantity: 0
            )
            return SelectedItem(item: item, quantity: sel.quantity)
        }
        return OptimizationResult(
            balanceInCents: balanceInCents,
            selectedItems: selectedItems,
            matchQuality: matchQuality
        )
    }

    static func from(_ result: OptimizationResult) -> SavedCalculation {
        let (kind, remaining) = matchQualityToStorage(result.matchQuality)
        let saved = SavedCalculation(
            balanceInCents: result.balanceInCents,
            matchQualityKind: kind,
            matchQualityRemainingCents: remaining
        )
        saved.items = result.selectedItems.map { sel in
            SavedResultItem(
                name: sel.item.name,
                priceInCents: sel.item.priceInCents,
                quantity: sel.quantity,
                calculation: saved
            )
        }
        return saved
    }

    private static func matchQualityToStorage(_ q: MatchQuality) -> (String, Int) {
        switch q {
        case .perfect: return ("perfect", 0)
        case .partial(let cents): return ("partial", cents)
        case .noSolution: return ("noSolution", 0)
        }
    }
}

@Model
final class SavedResultItem {
    var name: String
    var priceInCents: Int
    var quantity: Int
    var calculation: SavedCalculation?

    init(name: String, priceInCents: Int, quantity: Int, calculation: SavedCalculation? = nil) {
        self.name = name
        self.priceInCents = priceInCents
        self.quantity = quantity
        self.calculation = calculation
    }
}

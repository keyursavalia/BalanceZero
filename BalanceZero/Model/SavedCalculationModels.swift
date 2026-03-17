import Foundation
import SwiftData

@Model
final class SavedCalculation {
    var balanceInCents: Int
    var matchQualityKind: String // "perfect" | "partial" | "noSolution"
    var matchQualityRemainingCents: Int // only used when kind == "partial"
    var createdAt: Date
    /// JSON-encoded list of all optimal selections (each selection is an array of items).
    /// Stored to allow history to preserve and browse all combinations.
    var allSelectionsData: Data?
    @Relationship(deleteRule: .cascade, inverse: \SavedResultItem.calculation)
    var items: [SavedResultItem] = []

    init(
        balanceInCents: Int,
        matchQualityKind: String,
        matchQualityRemainingCents: Int = 0,
        allSelectionsData: Data? = nil,
        createdAt: Date = .now
    ) {
        self.balanceInCents = balanceInCents
        self.matchQualityKind = matchQualityKind
        self.matchQualityRemainingCents = matchQualityRemainingCents
        self.allSelectionsData = allSelectionsData
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
        
        let decodedSelections = Self.decodeAllSelections(allSelectionsData)
        let allSelections: [[SelectedItem]]
        if !decodedSelections.isEmpty {
            allSelections = decodedSelections.map { selection in
                selection.map { payload in
                    let item = ShoppingItem(
                        name: payload.name,
                        priceInCents: payload.priceInCents,
                        mandatoryQuantity: 0
                    )
                    return SelectedItem(item: item, quantity: payload.quantity)
                }
            }
        } else {
            allSelections = [selectedItems]
        }
        
        return OptimizationResult(
            balanceInCents: balanceInCents,
            selectedItems: selectedItems,
            matchQuality: matchQuality,
            allSelections: allSelections
        )
    }

    static func from(_ result: OptimizationResult) -> SavedCalculation {
        let (kind, remaining) = matchQualityToStorage(result.matchQuality)
        let encodedAllSelections = encodeAllSelections(result.allSelections)
        let saved = SavedCalculation(
            balanceInCents: result.balanceInCents,
            matchQualityKind: kind,
            matchQualityRemainingCents: remaining,
            allSelectionsData: encodedAllSelections
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
    
    private struct SelectionItemPayload: Codable, Hashable {
        let name: String
        let priceInCents: Int
        let quantity: Int
    }
    
    private static func encodeAllSelections(_ selections: [[SelectedItem]]) -> Data? {
        let payload: [[SelectionItemPayload]] = selections.map { selection in
            selection.map { sel in
                SelectionItemPayload(
                    name: sel.item.name,
                    priceInCents: sel.item.priceInCents,
                    quantity: sel.quantity
                )
            }
        }
        return try? JSONEncoder().encode(payload)
    }
    
    private static func decodeAllSelections(_ data: Data?) -> [[SelectionItemPayload]] {
        guard let data else { return [] }
        return (try? JSONDecoder().decode([[SelectionItemPayload]].self, from: data)) ?? []
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

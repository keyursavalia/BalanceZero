import Foundation

enum MatchQuality: Equatable, Hashable {
    case perfect                      // remainder == 0
    case partial(remainingCents: Int) // best we can do & remainder > 0
    case noSolution                   // no item fits at all
}

struct SelectedItem: Equatable, Hashable {
    let item: ShoppingItem
    let quantity: Int
    
    var totalCents: Int {
        item.priceInCents * quantity
    }
}

struct OptimizationResult: Equatable, Hashable {
    let balanceInCents: Int
    /// Primary selected items combination (usually the first / default choice).
    let selectedItems: [SelectedItem]
    let matchQuality: MatchQuality
    /// All optimal item combinations that achieve the same best spend (including the primary one).
    /// This will contain at least one entry when `matchQuality` is not `.noSolution`.
    let allSelections: [[SelectedItem]]
    
    var totalCentsSpent: Int {
        selectedItems.reduce(0) { $0 + $1.totalCents }
    }
    
    var remainingCents: Int {
        balanceInCents - totalCentsSpent
    }
}

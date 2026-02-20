import Foundation

enum MatchQuality: Equatable {
    case perfect                      // remainder == 0
    case partial(remainingCents: Int) // best we can do & remainder > 0
    case noSolution                   // no item fits at all
}

struct SelectedItem: Equatable {
    let item: ShoppingItem
    let quantity: Int
    
    var totalCents: Int {
        item.priceInCents * quantity
    }
}

struct OptimizationResult: Equatable {
    let balanceInCents: Int
    let selectedItems: [SelectedItem]
    let matchQuality: MatchQuality
    
    var totalCentsSpent: Int {
        selectedItems.reduce(0) { $0 + $1.totalCents }
    }
    
    var remainingCents: Int {
        balanceInCents - totalCentsSpent
    }
}

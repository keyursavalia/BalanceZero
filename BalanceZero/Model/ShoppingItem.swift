import Foundation

struct ShoppingItem: Identifiable, Hashable, Equatable {
    
    let id: UUID
    var name: String
    var priceInCents: Int // not using doubles to avoid floating-point drift
    
    init(id: UUID = UUID(), name: String, priceInCents: Int) {
        self.id = id
        self.name = name
        self.priceInCents = priceInCents
    }
    
    var priceForDisplay: Decimal {
        Decimal(priceInCents) / 100
    }
}

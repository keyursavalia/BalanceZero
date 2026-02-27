import Foundation

struct ShoppingItem: Identifiable, Hashable, Equatable {
    
    let id: UUID
    var name: String
    var priceInCents: Int // not using doubles to avoid floating-point drift
    /// Quantity user wants to include. 0 = optional; 1+ = mandatory in optimization.
    var mandatoryQuantity: Int
    
    init(id: UUID = UUID(), name: String, priceInCents: Int, mandatoryQuantity: Int = 0) {
        self.id = id
        self.name = name
        self.priceInCents = priceInCents
        self.mandatoryQuantity = mandatoryQuantity
    }
    
    var priceForDisplay: Decimal {
        Decimal(priceInCents) / 100
    }
}

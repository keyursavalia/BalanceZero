import Foundation

/// Defines how the optimizer treats the quantity for items with mandatoryQuantity > 0.
enum QuantityConstraint: String, Hashable, CaseIterable, Equatable {
    case exact   // Include exactly this many
    case minimum // Include at least this many; optimizer may add more for better balance
}

struct ShoppingItem: Identifiable, Hashable, Equatable {
    
    let id: UUID
    var name: String
    var priceInCents: Int // not using doubles to avoid floating-point drift
    /// Quantity user wants to include. 0 = optional; 1+ = mandatory in optimization.
    var mandatoryQuantity: Int
    /// How to treat quantity when mandatoryQuantity > 0. Ignored when quantity is 0.
    var quantityConstraint: QuantityConstraint
    
    init(id: UUID = UUID(), name: String, priceInCents: Int, mandatoryQuantity: Int = 0, quantityConstraint: QuantityConstraint = .exact) {
        self.id = id
        self.name = name
        self.priceInCents = priceInCents
        self.mandatoryQuantity = mandatoryQuantity
        self.quantityConstraint = quantityConstraint
    }
    
    var priceForDisplay: Decimal {
        Decimal(priceInCents) / 100
    }
}

import Foundation
import Combine
import SwiftUI

@MainActor
final class InputViewModel: ObservableObject {
    
    @Published var balanceText: String = ""
    @Published var items: [ShoppingItem] = [ShoppingItem(name: "", priceInCents: 0)]
    @Published var isCalculating: Bool = false
    @Published var result: OptimizationResult? = nil
    @Published var showValidationError: Bool = false
    @Published var validationMessage: String = ""
    
    private let optimizer = BalanceOptimizer()
    
    var balanceInCents: Int {
        
        let cleaned = balanceText
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        guard let value = Decimal(string: cleaned) else { return 0 }
        
        let cents = NSDecimalNumber(decimal: value * 100).intValue
        return max(0, cents)
    }
    
    var canCalculate: Bool {
        balanceInCents > 0 &&
        balanceInCents <= BalanceOptimizer.maximumSupportedCents &&
        items.contains { $0.priceInCents > 0 }
    }
    
    var itemCountLabel: String {
        let count = items.filter { $0.name.isEmpty || $0.priceInCents > 0 }.count
        return count == 1 ? "1 item" : "\(count) items"
    }
    
    func addItem() {
        items.append(ShoppingItem(name: " ", priceInCents: 0))
    }
    
    func removeItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        if items.isEmpty { addItem() }
    }

    func updateItemName(_ name: String, for id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].name = name
    }

    func updateItemPrice(_ priceText: String, for id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let cleaned = priceText
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        let cents: Int
        if let value = Decimal(string: cleaned) {
            cents = max(0, NSDecimalNumber(decimal: value * 100).intValue)
        } else {
            cents = 0
        }
        items[index].priceInCents = cents
    }

    func calculate() {
        guard canCalculate else {
            validationMessage = balanceInCents == 0
            ? "Please enter a valid card balance."
            : "Balance exceeds the supported maximum of $999.99."
            showValidationError = true
            return
        }
        
        isCalculating = true
        
        let optimizerInput = BalanceOptimizer.Input(
            balanceInCents: balanceInCents,
            items: items
        )
        let optimizer = self.optimizer
        
        Task.detached(priority: .userInitiated) { [weak self] in
            let result = optimizer.optimize(input: optimizerInput)
            await MainActor.run {
                self?.result = result
                self?.isCalculating = false
            }
        }
    }

    func reset() {
        balanceText = ""
        items = [ShoppingItem(name: "", priceInCents: 0)]
        result = nil
        showValidationError = false
        validationMessage = ""
    }
}

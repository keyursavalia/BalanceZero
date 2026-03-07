// BalanceOptimizer
//
// Algorithm choice -> bounded subset-sum with early exit
//
// Why? -> problem is variant of classic 0/1 knapsack (subset-sum). purchase of items is unbounded, so i have used unbounded knapsack approach operating on integer cents to avoid floating-point drift.
//         capacity is card balance (in cents), we look for a combination whose total equals the balance exactly; if not, we return a combination that maximises total spend.
//
// Note -> i have capped the search space to prevent runaway computation on large balances by imposing a practical ceiling, which is well within the use-case of the application.

import Foundation

struct BalanceOptimizer {
    
    static let maximumSupportedCents: Int = 99_999
    
    struct Input {
        let balanceInCents: Int
        let items: [ShoppingItem]
        
        var isValid: Bool {
            balanceInCents > 0 &&
            balanceInCents <= BalanceOptimizer.maximumSupportedCents &&
            items.contains { $0.priceInCents > 0 }
        }
    }
    
    func optimize(input: Input) -> OptimizationResult? {
        
        guard input.isValid else { return nil }
        
        let balance = input.balanceInCents
        
        // 1. Mandatory items: split into exact vs minimum
        let exactItems = input.items
            .filter { $0.mandatoryQuantity > 0 && $0.priceInCents > 0 && $0.quantityConstraint == .exact }
            .map { SelectedItem(item: $0, quantity: $0.mandatoryQuantity) }
        let minimumBaseItems = input.items
            .filter { $0.mandatoryQuantity > 0 && $0.priceInCents > 0 && $0.quantityConstraint == .minimum }
            .map { SelectedItem(item: $0, quantity: $0.mandatoryQuantity) }
        let mandatoryItems = exactItems + minimumBaseItems
        let mandatoryTotal = mandatoryItems.reduce(0) { $0 + $1.totalCents }

        if mandatoryTotal > balance {
            return OptimizationResult(
                balanceInCents: input.balanceInCents,
                selectedItems: [],
                matchQuality: .noSolution)
        }

        let remainingBalance = balance - mandatoryTotal

        // 2. Optional items: items with qty 0, plus minimum items (algorithm may add more for better optimization)
        let optionalItems = input.items.filter { item in
            item.priceInCents > 0 && (
                item.mandatoryQuantity == 0 ||
                (item.mandatoryQuantity > 0 && item.quantityConstraint == .minimum)
            )
        }
        let validItems = optionalItems.filter { $0.priceInCents > 0 && $0.priceInCents <= remainingBalance }
        
        var optionalSelected: [SelectedItem] = []
        var optionalTotal = 0

        if !validItems.isEmpty && remainingBalance > 0 {
            let (amount, items) = runDPAndReconstruct(capacity: remainingBalance, validItems: validItems)
            optionalTotal = amount
            optionalSelected = items
        }

        // Merge minimum-base items with optional extras (same item may appear in both)
        var mergedByItem: [UUID: (item: ShoppingItem, quantity: Int)] = [:]
        for sel in exactItems {
            mergedByItem[sel.item.id] = (sel.item, sel.quantity)
        }
        for sel in minimumBaseItems {
            let existing = mergedByItem[sel.item.id]
            let qty = (existing?.quantity ?? 0) + sel.quantity
            mergedByItem[sel.item.id] = (sel.item, qty)
        }
        for sel in optionalSelected {
            let existing = mergedByItem[sel.item.id]
            let qty = (existing?.quantity ?? 0) + sel.quantity
            mergedByItem[sel.item.id] = (sel.item, qty)
        }
        let mergedItems = mergedByItem.values.map { SelectedItem(item: $0.item, quantity: $0.quantity) }

        let allSelected = mergedItems.sorted { $0.totalCents > $1.totalCents }
        let totalSpent = mandatoryTotal + optionalTotal
        let leftover = balance - totalSpent
        let quality: MatchQuality = leftover == 0 ? .perfect : (mandatoryTotal > 0 || totalSpent > 0 ? .partial(remainingCents: leftover) : .noSolution)

        return OptimizationResult(
            balanceInCents: input.balanceInCents,
            selectedItems: allSelected,
            matchQuality: quality)
    }

    private func runDPAndReconstruct(capacity: Int, validItems: [ShoppingItem]) -> (Int, [SelectedItem]) {
        var dp = [Int](repeating: -1, count: capacity + 1)
        dp[0] = 0
        var itemUsed = [Int](repeating: -1, count: capacity + 1)

        for c in 1...capacity {
            for (index, item) in validItems.enumerated() {
                let price = item.priceInCents
                guard price <= c else { continue }
                let prev = dp[c - price]
                guard prev >= 0 else { continue }
                let candidate = price + prev
                if candidate > dp[c] {
                    dp[c] = candidate
                    itemUsed[c] = index
                }
            }
        }

        var bestAmount = 0
        for c in stride(from: capacity, through: 0, by: -1) {
            if dp[c] >= 0 {
                bestAmount = c
                break
            }
        }

        var selected: [Int: Int] = [:]
        var remaining = bestAmount
        while remaining > 0 {
            let idx = itemUsed[remaining]
            guard idx >= 0 else { break }
            selected[idx, default: 0] += 1
            remaining -= validItems[idx].priceInCents
        }
        let items = selected.map { idx, qty in SelectedItem(item: validItems[idx], quantity: qty) }
        return (bestAmount, items)
    }
}

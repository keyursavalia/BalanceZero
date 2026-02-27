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
        
        // 1. Mandatory items: user-required base
        let mandatoryItems = input.items
            .filter { $0.mandatoryQuantity > 0 && $0.priceInCents > 0 }
            .map { SelectedItem(item: $0, quantity: $0.mandatoryQuantity) }
        let mandatoryTotal = mandatoryItems.reduce(0) { $0 + $1.totalCents }

        if mandatoryTotal > balance {
            return OptimizationResult(
                balanceInCents: input.balanceInCents,
                selectedItems: [],
                matchQuality: .noSolution)
        }

        let remainingBalance = balance - mandatoryTotal

        // 2. Optional items: optimize to exhaust remaining balance
        let optionalItems = input.items.filter { $0.mandatoryQuantity == 0 }
        let validItems = optionalItems.filter { $0.priceInCents > 0 && $0.priceInCents <= remainingBalance }
        
        var optionalSelected: [SelectedItem] = []
        var optionalTotal = 0

        if !validItems.isEmpty && remainingBalance > 0 {
            let (amount, items) = runDPAndReconstruct(capacity: remainingBalance, validItems: validItems)
            optionalTotal = amount
            optionalSelected = items
        }

        let allSelected = (mandatoryItems + optionalSelected).sorted { $0.totalCents > $1.totalCents }
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

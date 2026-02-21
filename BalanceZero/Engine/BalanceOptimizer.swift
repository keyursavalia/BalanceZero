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
        
        let capacity = input.balanceInCents
        
        let validItems = input.items.filter { $0.priceInCents > 0 && $0.priceInCents <= capacity }
        guard !validItems.isEmpty else {
            return OptimizationResult(
                balanceInCents: input.balanceInCents,
                selectedItems: [],
                matchQuality: .noSolution)
        }
        
        // dp[c] = max spend achievable using all capacity
        var dp = [Int](repeating: -1, count: capacity + 1)  // we use -1 as sentinel for "unreachable"
        dp[0] = 0
        
        // itemUsed[c] = index into validItems that was last added to reach dp[c]
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
        
        // start from capacity and walk down to find out best reachable amount
        var bestAmount = 0
        for c in stride(from: capacity, through: 0, by: -1) {
            if dp[c] >= 0 {
                bestAmount = c
                break
            }
        }
        
        if bestAmount == 0 {
            return OptimizationResult(
                balanceInCents: input.balanceInCents,
                selectedItems: [],
                matchQuality: .noSolution)
        }
        
        // reconstruction: items chosen by backtracking
        var selected: [Int: Int] = [:]  // itemIndex -> quantity
        var remaining = bestAmount
        
        while remaining > 0 {
            let idx = itemUsed[remaining]
            guard idx >= 0 else { break }
            selected[idx, default: 0] += 1
            remaining -= validItems[idx].priceInCents
        }
        
        let selectedItems: [SelectedItem] = selected.map { idx, qty in
            SelectedItem(item: validItems[idx], quantity: qty)
        }.sorted { $0.totalCents > $1.totalCents }
        
        let leftover = input.balanceInCents - bestAmount
        let quality: MatchQuality = leftover == 0 ? .perfect : .partial(remainingCents: leftover)
        
        return OptimizationResult(
            balanceInCents: input.balanceInCents,
            selectedItems: selectedItems,
            matchQuality: quality)
    }
}

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
    private static let maxCombinationCount: Int = 100
    
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
                matchQuality: .noSolution,
                allSelections: [])
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
        
        var optionalTotal = 0
        var allOptionalSelections: [[SelectedItem]] = [[]]
        
        if !validItems.isEmpty && remainingBalance > 0 {
            let (amount, selections) = runDPAllOptimalSelections(
                capacity: remainingBalance,
                validItems: validItems,
                maxCombinations: BalanceOptimizer.maxCombinationCount
            )
            optionalTotal = amount
            if !selections.isEmpty {
                allOptionalSelections = selections
            }
        }
        
        // Merge minimum-base items with each optional selection (same item may appear in both)
        let mergedSelections: [[SelectedItem]] = allOptionalSelections.map { optionalSelection in
            mergeSelections(
                exactItems: exactItems,
                minimumBaseItems: minimumBaseItems,
                optionalItems: optionalSelection
            )
        }
        
        let primarySelection = mergedSelections.first ?? []
        let allSelected = primarySelection.sorted { $0.totalCents > $1.totalCents }
        let totalSpent = mandatoryTotal + optionalTotal
        let leftover = balance - totalSpent
        let quality: MatchQuality = leftover == 0 ? .perfect : (mandatoryTotal > 0 || totalSpent > 0 ? .partial(remainingCents: leftover) : .noSolution)

        return OptimizationResult(
            balanceInCents: input.balanceInCents,
            selectedItems: allSelected,
            matchQuality: quality,
            allSelections: mergedSelections)
    }
    
    private struct Choice {
        let itemIndex: Int
        let previousCapacity: Int
    }
    
    private func runDPAllOptimalSelections(
        capacity: Int,
        validItems: [ShoppingItem],
        maxCombinations: Int
    ) -> (Int, [[SelectedItem]]) {
        var dp = [Int](repeating: -1, count: capacity + 1)
        dp[0] = 0
        var predecessors = Array(repeating: [Choice](), count: capacity + 1)
        
        for c in 1...capacity {
            for (index, item) in validItems.enumerated() {
                let price = item.priceInCents
                guard price <= c else { continue }
                let prev = dp[c - price]
                guard prev >= 0 else { continue }
                let candidate = price + prev
                if candidate > dp[c] {
                    dp[c] = candidate
                    predecessors[c] = [Choice(itemIndex: index, previousCapacity: c - price)]
                } else if candidate == dp[c] && candidate >= 0 {
                    predecessors[c].append(Choice(itemIndex: index, previousCapacity: c - price))
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
        
        guard bestAmount > 0 else {
            return (0, [[]])
        }
        
        var results: [[SelectedItem]] = []
        var counts = [Int](repeating: 0, count: validItems.count)
        
        func dfs(_ c: Int) {
            if results.count >= maxCombinations { return }
            if c == 0 {
                let selection: [SelectedItem] = counts.enumerated().compactMap { index, qty in
                    qty > 0 ? SelectedItem(item: validItems[index], quantity: qty) : nil
                }
                results.append(selection)
                return
            }
            
            for choice in predecessors[c] {
                counts[choice.itemIndex] += 1
                dfs(choice.previousCapacity)
                counts[choice.itemIndex] -= 1
            }
        }
        
        dfs(bestAmount)
        
        return (bestAmount, results)
    }
    
    private func mergeSelections(
        exactItems: [SelectedItem],
        minimumBaseItems: [SelectedItem],
        optionalItems: [SelectedItem]
    ) -> [SelectedItem] {
        var mergedByItem: [UUID: (item: ShoppingItem, quantity: Int)] = [:]
        
        for sel in exactItems {
            let existing = mergedByItem[sel.item.id]
            let qty = (existing?.quantity ?? 0) + sel.quantity
            mergedByItem[sel.item.id] = (sel.item, qty)
        }
        
        for sel in minimumBaseItems {
            let existing = mergedByItem[sel.item.id]
            let qty = (existing?.quantity ?? 0) + sel.quantity
            mergedByItem[sel.item.id] = (sel.item, qty)
        }
        
        for sel in optionalItems {
            let existing = mergedByItem[sel.item.id]
            let qty = (existing?.quantity ?? 0) + sel.quantity
            mergedByItem[sel.item.id] = (sel.item, qty)
        }
        
        return mergedByItem.values
            .map { SelectedItem(item: $0.item, quantity: $0.quantity) }
            .sorted { $0.totalCents > $1.totalCents }
    }
}

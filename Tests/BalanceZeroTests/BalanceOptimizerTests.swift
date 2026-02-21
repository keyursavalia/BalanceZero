import XCTest
@testable import BalanceZero

final class BalanceOptimizerTests: XCTestCase {

    private let optimizer = BalanceOptimizer()

    // MARK: - Helpers

    private func item(id: UUID = UUID(), _ name: String, cents: Int) -> ShoppingItem {
        ShoppingItem(id: id, name: name, priceInCents: cents)
    }

    private func input(balance: Int, items: [ShoppingItem]) -> BalanceOptimizer.Input {
        BalanceOptimizer.Input(balanceInCents: balance, items: items)
    }

    // MARK: - Perfect Match Tests

    func testExactMatchSingleItem() {
        // Balance exactly equals one item price
        let i = input(balance: 428, items: [item("Celsius", cents: 428)])
        let result = optimizer.optimize(input: i)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.matchQuality, .perfect)
        XCTAssertEqual(result?.totalCentsSpent, 428)
        XCTAssertEqual(result?.remainingCents, 0)
    }

    func testExactMatchTwoDistinctItems() {
        // 300 + 227 = 527
        let i = input(balance: 527, items: [
            item("Coffee", cents: 300),
            item("Snack", cents: 227)
        ])
        let result = optimizer.optimize(input: i)
        XCTAssertEqual(result?.matchQuality, .perfect)
        XCTAssertEqual(result?.remainingCents, 0)
    }

    func testExactMatchRequiringMultipleQuantitiesOfSameItem() {
        // 3 x Celsius ($4.28) = $12.84, balance = $12.84
        let i = input(balance: 1284, items: [item("Celsius", cents: 428)])
        let result = optimizer.optimize(input: i)
        XCTAssertEqual(result?.matchQuality, .perfect)
        XCTAssertEqual(result?.totalCentsSpent, 1284)
        // Should have one SelectedItem with quantity 3
        let selected = result?.selectedItems.first
        XCTAssertEqual(selected?.quantity, 3)
    }

    func testPartialMatchWhenNoExactCombinationExists() {
        // Balance $5.00, only item $3.23 — best is 1 item ($3.23), leftover $1.77
        let i = input(balance: 500, items: [item("Coffee", cents: 323)])
        let result = optimizer.optimize(input: i)
        // Could fit 1 item (323) or... optimizer may find better combo
        // 500 / 323 = 1 remainder 177; can't fit another 323
        // So best is 1 x 323 = 323
        XCTAssertNotNil(result)
        if case .partial(let remaining) = result?.matchQuality {
            XCTAssertGreaterThan(remaining, 0)
            XCTAssertLessThan(remaining, 500)
        } else if result?.matchQuality == .perfect {
            XCTAssertEqual(result?.remainingCents, 0)
        }
        // Spend should not exceed balance
        XCTAssertLessThanOrEqual(result?.totalCentsSpent ?? 0, 500)
    }

    func testNoSolutionWhenAllItemsExceedBalance() {
        // Balance $1.00, all items cost more
        let i = input(balance: 100, items: [
            item("RedBull", cents: 410),
            item("Coffee", cents: 323)
        ])
        let result = optimizer.optimize(input: i)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.matchQuality, .noSolution)
        XCTAssertTrue(result?.selectedItems.isEmpty ?? false)
    }

    func testNilReturnedForZeroBalance() {
        let i = input(balance: 0, items: [item("Item", cents: 100)])
        XCTAssertFalse(i.isValid)
        XCTAssertNil(optimizer.optimize(input: i))
    }

    func testNilReturnedForEmptyItems() {
        let i = input(balance: 500, items: [])
        XCTAssertFalse(i.isValid)
        XCTAssertNil(optimizer.optimize(input: i))
    }

    func testNilReturnedForBalanceExceedingMaximum() {
        let i = input(balance: BalanceOptimizer.maximumSupportedCents + 1, items: [item("X", cents: 100)])
        XCTAssertFalse(i.isValid)
        XCTAssertNil(optimizer.optimize(input: i))
    }

    func testItemsWithZeroPriceAreIgnored() {
        // One zero-price item, one valid item
        let i = input(balance: 300, items: [
            item("Free", cents: 0),
            item("Coffee", cents: 300)
        ])
        let result = optimizer.optimize(input: i)
        XCTAssertEqual(result?.matchQuality, .perfect)
    }

    func testOriginalBalancePreservedInResult() {
        let i = input(balance: 1000, items: [item("Item", cents: 500)])
        let result = optimizer.optimize(input: i)
        XCTAssertEqual(result?.balanceInCents, 1000)
    }

    func testSpendDoesNotExceedBalance() {
        // Fuzz-style: varied prices, verify invariant
        let items = [
            item("A", cents: 137),
            item("B", cents: 289),
            item("C", cents: 450),
            item("D", cents: 99)
        ]
        for balance in stride(from: 100, through: 2000, by: 50) {
            let i = input(balance: balance, items: items)
            if let result = optimizer.optimize(input: i) {
                XCTAssertLessThanOrEqual(result.totalCentsSpent, balance,
                    "Spent \(result.totalCentsSpent) exceeds balance \(balance)")
            }
        }
    }

    func testLargeBalanceCompletesInReasonableTime() {
        // $500.00 with several items — DP over 50000 cells
        let items = [
            item("A", cents: 428),
            item("B", cents: 323),
            item("C", cents: 410),
            item("D", cents: 199)
        ]
        let i = input(balance: 50000, items: items)
        let start = Date()
        _ = optimizer.optimize(input: i)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 2.0, "Optimizer took too long: \(elapsed)s")
    }

    // MARK: - Result Structure Tests

    func testSelectedItemQuantitiesArePositive() {
        let i = input(balance: 856, items: [item("Celsius", cents: 428)])
        let result = optimizer.optimize(input: i)
        result?.selectedItems.forEach { selected in
            XCTAssertGreaterThan(selected.quantity, 0)
        }
    }

    func testSelectedItemTotalCentsIsConsistent() {
        let i = input(balance: 1284, items: [item("Celsius", cents: 428)])
        let result = optimizer.optimize(input: i)
        result?.selectedItems.forEach { selected in
            XCTAssertEqual(selected.totalCents, selected.item.priceInCents * selected.quantity)
        }
    }
}

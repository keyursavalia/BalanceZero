import Testing
import Foundation
@testable import BalanceZero

// MARK: - Balance Optimizer

@Suite("Balance Optimizer")
struct BalanceOptimizerSuite {

    private let optimizer = BalanceOptimizer()

    private func item(
        _ name: String,
        cents: Int,
        mandatoryQuantity: Int = 0,
        constraint: QuantityConstraint = .exact
    ) -> ShoppingItem {
        ShoppingItem(name: name, priceInCents: cents, mandatoryQuantity: mandatoryQuantity, quantityConstraint: constraint)
    }

    private func input(balance: Int, items: [ShoppingItem]) -> BalanceOptimizer.Input {
        BalanceOptimizer.Input(balanceInCents: balance, items: items)
    }

    // MARK: Perfect Match

    @Test func singleItemExactlyMatchesBalance() {
        let result = optimizer.optimize(input: input(balance: 428, items: [item("Celsius", cents: 428)]))
        #expect(result?.matchQuality == .perfect)
        #expect(result?.totalCentsSpent == 428)
        #expect(result?.remainingCents == 0)
    }

    @Test func twoDistinctItemsSumToBalance() {
        let result = optimizer.optimize(input: input(balance: 527, items: [
            item("Coffee", cents: 300),
            item("Snack", cents: 227)
        ]))
        #expect(result?.matchQuality == .perfect)
        #expect(result?.remainingCents == 0)
    }

    @Test func multipleQuantitiesOfOneSingleItemReachBalance() {
        let result = optimizer.optimize(input: input(balance: 1284, items: [item("Celsius", cents: 428)]))
        #expect(result?.matchQuality == .perfect)
        #expect(result?.totalCentsSpent == 1284)
        #expect(result?.selectedItems.first?.quantity == 3)
    }

    @Test func minimumOneCentBalanceWithOneCentItem_perfectMatch() {
        let result = optimizer.optimize(input: input(balance: 1, items: [item("Penny", cents: 1)]))
        #expect(result?.matchQuality == .perfect)
        #expect(result?.totalCentsSpent == 1)
    }

    @Test func allItemsHaveSamePriceAndSumToBalance() {
        let items = (0..<5).map { item("Item\($0)", cents: 100) }
        let result = optimizer.optimize(input: input(balance: 500, items: items))
        #expect(result?.matchQuality == .perfect)
        #expect(result?.totalCentsSpent == 500)
    }

    @Test func singleExpensiveItemAmongChearperOnesStillReachesBalance() {
        let result = optimizer.optimize(input: input(balance: 99999, items: [
            item("Expensive", cents: 99999),
            item("Cheap", cents: 100)
        ]))
        #expect(result?.matchQuality == .perfect)
    }

    // MARK: Partial Match

    @Test func partialMatchReturnedWhenNoExactCombinationExists() {
        let result = optimizer.optimize(input: input(balance: 500, items: [item("Coffee", cents: 323)]))
        #expect(result != nil)
        guard let result else { return }
        #expect(result.totalCentsSpent <= 500)
        if case .partial(let remaining) = result.matchQuality {
            #expect(remaining > 0)
            #expect(remaining < 500)
        }
    }

    @Test func primeBalanceWithItemThatCannotDivideItEvenly_partialMatch() {
        // 97 (prime) / 13 = 7 r 6 → 7 * 13 = 91, remaining = 6
        let result = optimizer.optimize(input: input(balance: 97, items: [item("Item", cents: 13)]))
        guard let result else { return }
        #expect(result.totalCentsSpent == 91)
        #expect(result.matchQuality == .partial(remainingCents: 6))
    }

    // MARK: No Solution

    @Test func allItemsPricedAboveBalance_noSolution() {
        let result = optimizer.optimize(input: input(balance: 100, items: [
            item("RedBull", cents: 410),
            item("Coffee", cents: 323)
        ]))
        #expect(result?.matchQuality == .noSolution)
        #expect(result?.selectedItems.isEmpty == true)
    }

    @Test func singleItemOneCentAboveBalance_noSolution() {
        let result = optimizer.optimize(input: input(balance: 50, items: [item("Item", cents: 51)]))
        #expect(result?.matchQuality == .noSolution)
    }

    // MARK: Invalid Input

    @Test func zeroBalanceIsInvalidAndReturnsNil() {
        let i = input(balance: 0, items: [item("Item", cents: 100)])
        #expect(!i.isValid)
        #expect(optimizer.optimize(input: i) == nil)
    }

    @Test func emptyItemListIsInvalidAndReturnsNil() {
        let i = input(balance: 500, items: [])
        #expect(!i.isValid)
        #expect(optimizer.optimize(input: i) == nil)
    }

    @Test func balanceOneAboveMaxIsInvalidAndReturnsNil() {
        let i = input(balance: BalanceOptimizer.maximumSupportedCents + 1, items: [item("X", cents: 100)])
        #expect(!i.isValid)
        #expect(optimizer.optimize(input: i) == nil)
    }

    @Test func allZeroPriceItemsIsInvalidAndReturnsNil() {
        let i = input(balance: 500, items: [item("Free", cents: 0), item("AlsoFree", cents: 0)])
        #expect(!i.isValid)
        #expect(optimizer.optimize(input: i) == nil)
    }

    @Test func negativeItemPriceMixedWithValidItem_negativeItemIgnored() {
        let negative = ShoppingItem(name: "Weird", priceInCents: -100)
        let valid = item("Valid", cents: 300)
        let result = optimizer.optimize(input: input(balance: 300, items: [negative, valid]))
        #expect(result?.matchQuality == .perfect)
        #expect(result?.selectedItems.contains { $0.item.name == "Valid" } == true)
        #expect(result?.selectedItems.contains { $0.item.name == "Weird" } != true)
    }

    @Test func intMaxPriceItem_filteredWithoutCrash() {
        let huge = ShoppingItem(name: "Huge", priceInCents: Int.max)
        let normal = item("Normal", cents: 100)
        let result = optimizer.optimize(input: input(balance: 100, items: [huge, normal]))
        #expect(result != nil)
        #expect(result?.matchQuality == .perfect)
    }

    // MARK: Invariants

    @Test func spendNeverExceedsBalanceAcrossVariedInputs() {
        let items = [
            item("A", cents: 137),
            item("B", cents: 289),
            item("C", cents: 450),
            item("D", cents: 99)
        ]
        for balance in stride(from: 100, through: 2000, by: 50) {
            if let result = optimizer.optimize(input: input(balance: balance, items: items)) {
                #expect(result.totalCentsSpent <= balance,
                        "Spent \(result.totalCentsSpent) exceeds balance \(balance)")
            }
        }
    }

    @Test func originalBalancePreservedInResult() {
        let result = optimizer.optimize(input: input(balance: 1000, items: [item("Item", cents: 500)]))
        #expect(result?.balanceInCents == 1000)
    }

    @Test func allSelectedItemQuantitiesArePositive() {
        let result = optimizer.optimize(input: input(balance: 856, items: [item("Celsius", cents: 428)]))
        result?.selectedItems.forEach { #expect($0.quantity > 0) }
    }

    @Test func selectedItemTotalCentsEqualsPriceTimesQuantity() {
        let result = optimizer.optimize(input: input(balance: 1284, items: [item("Celsius", cents: 428)]))
        result?.selectedItems.forEach {
            #expect($0.totalCents == $0.item.priceInCents * $0.quantity)
        }
    }

    @Test func zeroPriceItemsMixedWithValidItems_zeroItemsNotSelected() {
        let result = optimizer.optimize(input: input(balance: 300, items: [
            item("Free", cents: 0),
            item("Coffee", cents: 300)
        ]))
        #expect(result?.matchQuality == .perfect)
        #expect(result?.selectedItems.contains { $0.item.priceInCents == 0 } != true)
    }

    @Test func fiftyItemsWithRandomPrices_nocrashAndSpendWithinBalance() {
        let items = (0..<50).map { item("Item\($0)", cents: ($0 + 1) * 7) }
        let result = optimizer.optimize(input: input(balance: 5000, items: items))
        if let result {
            #expect(result.totalCentsSpent <= 5000)
        }
    }

    // MARK: Mandatory Quantities

    @Test func exactMandatoryQuantityIncludedExactly() {
        let avocado = item("Avocado", cents: 399, mandatoryQuantity: 3, constraint: .exact)
        let result = optimizer.optimize(input: input(balance: 1500, items: [avocado]))
        let selected = result?.selectedItems.first { $0.item.name == "Avocado" }
        #expect(selected?.quantity == 3)
    }

    @Test func minimumMandatoryQuantityAllowsOptimizerToAddMore() {
        let tomato = item("Tomato", cents: 29, mandatoryQuantity: 10, constraint: .minimum)
        let result = optimizer.optimize(input: input(balance: 500, items: [tomato]))
        let selected = result?.selectedItems.first { $0.item.name == "Tomato" }
        #expect((selected?.quantity ?? 0) >= 10)
        #expect(selected?.quantity == 17)
        #expect(result?.matchQuality == .partial(remainingCents: 7))
    }

    @Test func minimumConstraintDoesNotExceedBalanceWhenNoRoomRemains() {
        let i = ShoppingItem(name: "Item", priceInCents: 100, mandatoryQuantity: 5, quantityConstraint: .minimum)
        let result = optimizer.optimize(input: input(balance: 500, items: [i]))
        let selected = result?.selectedItems.first
        #expect(selected?.quantity == 5)
        #expect(result?.matchQuality == .perfect)
    }

    @Test func exactAndMinimumConstraintsWorkTogetherInSameInput() {
        let avocado = item("Avocado", cents: 400, mandatoryQuantity: 2, constraint: .exact)
        let tomato = item("Tomato", cents: 50, mandatoryQuantity: 3, constraint: .minimum)
        let result = optimizer.optimize(input: input(balance: 1000, items: [avocado, tomato]))
        let avocadoQty = result?.selectedItems.first { $0.item.name == "Avocado" }?.quantity
        let tomatoQty = result?.selectedItems.first { $0.item.name == "Tomato" }?.quantity
        #expect(avocadoQty == 2)
        #expect((tomatoQty ?? 0) >= 3)
        #expect(tomatoQty == 4)
    }

    @Test func singleMandatoryItemExceedingBalance_noSolution() {
        let expensive = item("Expensive", cents: 1000, mandatoryQuantity: 1, constraint: .exact)
        let result = optimizer.optimize(input: input(balance: 500, items: [expensive]))
        #expect(result?.matchQuality == .noSolution)
    }

    @Test func twoCombinedMandatoryItemsExceedingBalance_noSolution() {
        let a = item("A", cents: 300, mandatoryQuantity: 1, constraint: .exact)
        let b = item("B", cents: 300, mandatoryQuantity: 1, constraint: .exact)
        let result = optimizer.optimize(input: input(balance: 500, items: [a, b]))
        #expect(result?.matchQuality == .noSolution)
    }

    @Test func mandatoryItemsAloneExhaustBalance_perfectMatchWithNoOptionalsNeeded() {
        let a = item("A", cents: 200, mandatoryQuantity: 1, constraint: .exact)
        let b = item("B", cents: 300, mandatoryQuantity: 1, constraint: .exact)
        let result = optimizer.optimize(input: input(balance: 500, items: [a, b]))
        #expect(result?.matchQuality == .perfect)
        #expect(result?.totalCentsSpent == 500)
    }

    @Test func mandatoryQuantityZeroWithMinimumConstraint_treatedAsOptional() {
        let i = ShoppingItem(name: "Item", priceInCents: 100, mandatoryQuantity: 0, quantityConstraint: .minimum)
        let result = optimizer.optimize(input: input(balance: 300, items: [i]))
        let selected = result?.selectedItems.first
        #expect(selected?.quantity == 3)
        #expect(result?.matchQuality == .perfect)
    }

    // MARK: Multiple Combinations

    @Test func primarySelectionAlwaysMatchesFirstEntryInAllSelections() {
        let result = optimizer.optimize(input: input(balance: 500, items: [
            item("A", cents: 200),
            item("B", cents: 300)
        ]))
        guard let result else { return }
        #expect(!result.allSelections.isEmpty)
        #expect(result.selectedItems == result.allSelections.first)
    }

    @Test func multiplePerfectCombinationsAllEnumerated() {
        // A=2, B=4, C=6, balance=8 → B+B and A+C are both perfect spends
        let result = optimizer.optimize(input: input(balance: 8, items: [
            item("A", cents: 2),
            item("B", cents: 4),
            item("C", cents: 6)
        ]))
        guard let result else { return }
        #expect(result.matchQuality == .perfect)
        #expect(result.allSelections.count >= 2)
        for selection in result.allSelections {
            let spent = selection.reduce(0) { $0 + $1.totalCents }
            #expect(spent == result.balanceInCents)
        }
    }

    @Test func twoIdenticalPricedItemsBothCountAsSeparatePerfectCombinations() {
        // Each item alone perfectly fills the balance
        let result = optimizer.optimize(input: input(balance: 500, items: [
            item("A", cents: 500),
            item("B", cents: 500)
        ]))
        guard let result else { return }
        #expect(result.matchQuality == .perfect)
        #expect(result.allSelections.count == 2)
    }

    @Test func combinationCountCappedAtOneHundred() {
        // 10 symmetric items all at price 2, balance 20 → explosion of combinations
        let items = (0..<10).map { item("Item\($0)", cents: 2) }
        let result = optimizer.optimize(input: input(balance: 20, items: items))
        guard let result else { return }
        #expect(result.allSelections.count <= 100)
    }

    @Test func noSolutionResultHasEmptyOrSingleEmptyAllSelections() {
        let result = optimizer.optimize(input: input(balance: 100, items: [
            item("A", cents: 500),
            item("B", cents: 600)
        ]))
        guard let result else { return }
        #expect(result.matchQuality == .noSolution)
        if result.allSelections.isEmpty {
            #expect(result.selectedItems.isEmpty)
        } else {
            #expect(result.allSelections.count == 1)
            #expect(result.allSelections[0].isEmpty)
        }
    }

    // MARK: Performance

    @Test func maximumSupportedBalanceCompletesWithinThreeSeconds() {
        let items = [
            item("A", cents: 428),
            item("B", cents: 323),
            item("C", cents: 410),
            item("D", cents: 199)
        ]
        let start = Date()
        _ = optimizer.optimize(input: input(balance: BalanceOptimizer.maximumSupportedCents, items: items))
        #expect(Date().timeIntervalSince(start) < 3.0)
    }

    @Test func largeBalanceWithTinyItemCompletesWithinThreeSeconds() {
        let start = Date()
        _ = optimizer.optimize(input: input(balance: 90000, items: [item("Item", cents: 7)]))
        #expect(Date().timeIntervalSince(start) < 3.0)
    }
}

// MARK: - Currency Input Helper

@Suite("Currency Input Helper")
struct CurrencyInputHelperSuite {

    @Test func extractDigitsFiltersLettersAndSymbols() {
        #expect(CurrencyInputHelper.extractDigits(from: "abc$1.23def") == "123")
    }

    @Test func extractDigitsFromEmptyStringReturnsEmpty() {
        #expect(CurrencyInputHelper.extractDigits(from: "") == "")
    }

    @Test func extractDigitsRespectsDefaultMaxOfFive() {
        #expect(CurrencyInputHelper.extractDigits(from: "123456789") == "12345")
    }

    @Test func extractDigitsRespectsCustomMaxDigits() {
        #expect(CurrencyInputHelper.extractDigits(from: "12345678", maxDigits: 7) == "1234567")
    }

    @Test func extractDigitsFromSymbolsOnlyReturnsEmpty() {
        #expect(CurrencyInputHelper.extractDigits(from: "$$$@@@!!!") == "")
    }

    @Test func extractDigitsPreservesLeadingZeros() {
        #expect(CurrencyInputHelper.extractDigits(from: "00123") == "00123")
    }

    @Test func formatEmptyStringReturnsZeroAmount() {
        #expect(CurrencyInputHelper.formatDigitsToAmount("") == "0.00")
    }

    @Test func formatSingleDigitProducesPennyRepresentation() {
        #expect(CurrencyInputHelper.formatDigitsToAmount("1") == "0.01")
    }

    @Test func formatTwoDigitsProducesCentsRepresentation() {
        #expect(CurrencyInputHelper.formatDigitsToAmount("12") == "0.12")
    }

    @Test func formatThreeDigitsProducesOneDollarRepresentation() {
        #expect(CurrencyInputHelper.formatDigitsToAmount("123") == "1.23")
    }

    @Test func formatFiveDigitsProducesThreeDigitDollarRepresentation() {
        #expect(CurrencyInputHelper.formatDigitsToAmount("12345") == "123.45")
    }

    @Test func formatLeadingZerosStrippedFromDollarsPart() {
        #expect(CurrencyInputHelper.formatDigitsToAmount("00100") == "1.00")
    }

    @Test func formatAllZerosProducesZeroAmount() {
        #expect(CurrencyInputHelper.formatDigitsToAmount("000") == "0.00")
    }

    @Test func centsFromFormattedParsesTypicalAmount() {
        #expect(CurrencyInputHelper.centsFromFormatted("1.23") == 123)
    }

    @Test func centsFromFormattedHandlesZero() {
        #expect(CurrencyInputHelper.centsFromFormatted("0.00") == 0)
    }

    @Test func centsFromFormattedHandlesMaxSupportedAmount() {
        #expect(CurrencyInputHelper.centsFromFormatted("999.99") == 99999)
    }

    @Test func centsFromFormattedReturnZeroForNonNumericInput() {
        #expect(CurrencyInputHelper.centsFromFormatted("abc") == 0)
    }

    @Test func centsFromFormattedReturnZeroForEmptyString() {
        #expect(CurrencyInputHelper.centsFromFormatted("") == 0)
    }

    @Test func formattedFromCentsHandlesZero() {
        #expect(CurrencyInputHelper.formattedFromCents(0) == "0.00")
    }

    @Test func formattedFromCentsHandlesSinglePenny() {
        #expect(CurrencyInputHelper.formattedFromCents(1) == "0.01")
    }

    @Test func formattedFromCentsHandlesExactDollar() {
        #expect(CurrencyInputHelper.formattedFromCents(100) == "1.00")
    }

    @Test func formattedFromCentsHandlesMaxSupportedAmount() {
        #expect(CurrencyInputHelper.formattedFromCents(99999) == "999.99")
    }

    @Test func formattedFromCentsHandlesTwoDigitCentsWithLeadingZero() {
        #expect(CurrencyInputHelper.formattedFromCents(99) == "0.99")
    }

    @Test func roundTripPreservesCentsForAllCommonValues() {
        for cents in [0, 1, 9, 99, 100, 101, 999, 1000, 9999, 10000, 99999] {
            let formatted = CurrencyInputHelper.formattedFromCents(cents)
            let roundTripped = CurrencyInputHelper.centsFromFormatted(formatted)
            #expect(roundTripped == cents, "Round-trip failed for \(cents) cents via \"\(formatted)\"")
        }
    }
}

// MARK: - Mock Optimizer

final class MockBalanceOptimizer: BalanceOptimizerProtocol, @unchecked Sendable {
    let stubbedResult: OptimizationResult?
    private(set) var capturedInput: BalanceOptimizer.Input?

    init(stubbedResult: OptimizationResult? = nil) {
        self.stubbedResult = stubbedResult
    }

    func optimize(input: BalanceOptimizer.Input) -> OptimizationResult? {
        capturedInput = input
        return stubbedResult
    }
}

// MARK: - Input View Model

@Suite("Input View Model")
@MainActor
struct InputViewModelSuite {

    // MARK: Initial state

    @Test func initialBalanceTextIsEmpty() {
        let vm = InputViewModel()
        #expect(vm.balanceText == "")
    }

    @Test func initialItemsListContainsExactlyOneEmptyItem() {
        let vm = InputViewModel()
        #expect(vm.items.count == 1)
        #expect(vm.items.first?.name == "")
        #expect(vm.items.first?.priceInCents == 0)
    }

    @Test func initialStateCannotCalculate() {
        let vm = InputViewModel()
        #expect(!vm.canCalculate)
    }

    // MARK: addItem

    @Test func addItemAppendsEmptyNameItem() {
        let vm = InputViewModel()
        vm.addItem()
        #expect(vm.items.last?.name == "")
    }

    @Test func addItemNeverAppendsSpaceAsName() {
        let vm = InputViewModel()
        vm.addItem()
        #expect(vm.items.last?.name != " ")
    }

    @Test func addItemIncreasesCountByOne() {
        let vm = InputViewModel()
        vm.addItem()
        #expect(vm.items.count == 2)
    }

    @Test func addItemMultipleTimes() {
        let vm = InputViewModel()
        for _ in 0..<9 { vm.addItem() }
        #expect(vm.items.count == 10)
    }

    // MARK: removeItem

    @Test func removeItemReducesCount() {
        let vm = InputViewModel()
        vm.addItem()
        vm.removeItem(at: IndexSet(integer: 0))
        #expect(vm.items.count == 1)
    }

    @Test func removeLastItemAutomaticallyReplacesWithEmptyItem() {
        let vm = InputViewModel()
        vm.removeItem(at: IndexSet(integer: 0))
        #expect(vm.items.count == 1)
        #expect(vm.items.first?.priceInCents == 0)
    }

    @Test func removeAllItemsLeavesExactlyOneItem() {
        let vm = InputViewModel()
        vm.addItem()
        vm.addItem()
        vm.removeItem(at: IndexSet([0, 1, 2]))
        #expect(vm.items.count == 1)
    }

    @Test func removeWithEmptyIndexSetChangesNothing() {
        let vm = InputViewModel()
        vm.removeItem(at: IndexSet())
        #expect(vm.items.count == 1)
    }

    // MARK: updateItemName

    @Test func updateItemNameModifiesCorrectItemByID() {
        let vm = InputViewModel()
        let id = vm.items[0].id
        vm.updateItemName("Coffee", for: id)
        #expect(vm.items[0].name == "Coffee")
    }

    @Test func updateItemNameWithUnknownIDDoesNotCrashOrChangeState() {
        let vm = InputViewModel()
        let before = vm.items.map(\.name)
        vm.updateItemName("Ghost", for: UUID())
        #expect(vm.items.map(\.name) == before)
    }

    // MARK: updateItemPrice

    @Test func updateItemPriceParsesDollarAndCentsString() {
        let vm = InputViewModel()
        let id = vm.items[0].id
        vm.updateItemPrice("1.99", for: id)
        #expect(vm.items[0].priceInCents == 199)
    }

    @Test func updateItemPriceStripsDollarSignBeforeParsing() {
        let vm = InputViewModel()
        let id = vm.items[0].id
        vm.updateItemPrice("$4.28", for: id)
        #expect(vm.items[0].priceInCents == 428)
    }

    @Test func updateItemPriceStripsThousandsCommaBeforeParsing() {
        let vm = InputViewModel()
        let id = vm.items[0].id
        vm.updateItemPrice("1,000.00", for: id)
        #expect(vm.items[0].priceInCents == 100000)
    }

    @Test func updateItemPriceWithNonNumericStringSetsZero() {
        let vm = InputViewModel()
        let id = vm.items[0].id
        vm.updateItemPrice("notanumber", for: id)
        #expect(vm.items[0].priceInCents == 0)
    }

    @Test func updateItemPriceWithUnknownIDDoesNotCrashOrChangeState() {
        let vm = InputViewModel()
        let before = vm.items.map(\.priceInCents)
        vm.updateItemPrice("5.00", for: UUID())
        #expect(vm.items.map(\.priceInCents) == before)
    }

    // MARK: balanceInCents

    @Test func balanceInCentsParsesStandardDollarAmount() {
        let vm = InputViewModel()
        vm.balanceText = "10.00"
        #expect(vm.balanceInCents == 1000)
    }

    @Test func balanceInCentsStripsDollarSign() {
        let vm = InputViewModel()
        vm.balanceText = "$25.50"
        #expect(vm.balanceInCents == 2550)
    }

    @Test func balanceInCentsStripsThousandsComma() {
        let vm = InputViewModel()
        vm.balanceText = "$1,234.56"
        #expect(vm.balanceInCents == 123456)
    }

    @Test func balanceInCentsTrimsLeadingAndTrailingWhitespace() {
        let vm = InputViewModel()
        vm.balanceText = "  50.00  "
        #expect(vm.balanceInCents == 5000)
    }

    @Test func balanceInCentsReturnsZeroForEmptyText() {
        let vm = InputViewModel()
        vm.balanceText = ""
        #expect(vm.balanceInCents == 0)
    }

    @Test func balanceInCentsReturnsZeroForNonNumericText() {
        let vm = InputViewModel()
        vm.balanceText = "hello"
        #expect(vm.balanceInCents == 0)
    }

    // MARK: canCalculate

    @Test func canCalculateIsFalseWhenBalanceIsZero() {
        let vm = InputViewModel()
        vm.balanceText = "0.00"
        vm.items[0].priceInCents = 100
        #expect(!vm.canCalculate)
    }

    @Test func canCalculateIsFalseWhenAllItemsHaveZeroPrice() {
        let vm = InputViewModel()
        vm.balanceText = "10.00"
        #expect(!vm.canCalculate)
    }

    @Test func canCalculateIsFalseWhenBalanceExceedsMaximum() {
        let vm = InputViewModel()
        vm.balanceText = "1000.00"
        vm.items[0].priceInCents = 100
        #expect(!vm.canCalculate)
    }

    @Test func canCalculateIsTrueWithValidBalanceAndAtLeastOnePricedItem() {
        let vm = InputViewModel()
        vm.balanceText = "10.00"
        vm.items[0].priceInCents = 500
        #expect(vm.canCalculate)
    }

    @Test func canCalculateIsTrueAtExactMaximumBalance() {
        let vm = InputViewModel()
        vm.balanceText = "999.99"
        vm.items[0].priceInCents = 100
        #expect(vm.canCalculate)
    }

    // MARK: calculate — validation messages

    @Test func calculateWithZeroBalanceShowsBalanceValidationMessage() {
        let vm = InputViewModel()
        vm.items[0].priceInCents = 100
        vm.calculate()
        #expect(vm.showValidationError)
        #expect(vm.validationMessage == "Please enter a valid card balance.")
    }

    @Test func calculateWithExcessiveBalanceShowsMaximumLimitMessage() {
        let vm = InputViewModel()
        vm.balanceText = "9999.99"
        vm.items[0].priceInCents = 100
        vm.calculate()
        #expect(vm.showValidationError)
        #expect(vm.validationMessage.contains("999.99"))
    }

    @Test func calculateWithValidBalanceButNoPricedItemsShowsItemsRequiredMessage() {
        let vm = InputViewModel()
        vm.balanceText = "10.00"
        vm.calculate()
        #expect(vm.showValidationError)
        #expect(vm.validationMessage.lowercased().contains("item"))
    }

    // MARK: calculate — async result

    @Test func calculateWithMockOptimizerSetsResultOnCompletion() async throws {
        let expected = OptimizationResult(
            balanceInCents: 1000,
            selectedItems: [],
            matchQuality: .perfect,
            allSelections: [[]]
        )
        let mock = MockBalanceOptimizer(stubbedResult: expected)
        let vm = InputViewModel(optimizer: mock)
        vm.balanceText = "10.00"
        vm.items[0].priceInCents = 500

        vm.calculate()
        try await Task.sleep(for: .milliseconds(200))

        #expect(vm.result == expected)
        #expect(!vm.isCalculating)
    }

    @Test func calculateWithMockReturningNilLeavesResultNil() async throws {
        let mock = MockBalanceOptimizer(stubbedResult: nil)
        let vm = InputViewModel(optimizer: mock)
        vm.balanceText = "10.00"
        vm.items[0].priceInCents = 500

        vm.calculate()
        try await Task.sleep(for: .milliseconds(200))

        #expect(vm.result == nil)
        #expect(!vm.isCalculating)
    }

    @Test func calculateSetsIsCalculatingTrueImmediately() {
        let mock = MockBalanceOptimizer(stubbedResult: nil)
        let vm = InputViewModel(optimizer: mock)
        vm.balanceText = "10.00"
        vm.items[0].priceInCents = 100

        vm.calculate()
        #expect(vm.isCalculating)
    }

    @Test func calculateForwardsCorrectInputToOptimizer() async throws {
        let mock = MockBalanceOptimizer(stubbedResult: nil)
        let vm = InputViewModel(optimizer: mock)
        vm.balanceText = "5.00"
        vm.items[0].priceInCents = 250

        vm.calculate()
        try await Task.sleep(for: .milliseconds(200))

        #expect(mock.capturedInput?.balanceInCents == 500)
        #expect(mock.capturedInput?.items.first?.priceInCents == 250)
    }

    // MARK: reset

    @Test func resetClearsBalanceText() {
        let vm = InputViewModel()
        vm.balanceText = "50.00"
        vm.reset()
        #expect(vm.balanceText == "")
    }

    @Test func resetClearsResult() {
        let vm = InputViewModel()
        vm.result = OptimizationResult(
            balanceInCents: 100,
            selectedItems: [],
            matchQuality: .perfect,
            allSelections: []
        )
        vm.reset()
        #expect(vm.result == nil)
    }

    @Test func resetClearsValidationErrorAndMessage() {
        let vm = InputViewModel()
        vm.showValidationError = true
        vm.validationMessage = "Some error"
        vm.reset()
        #expect(!vm.showValidationError)
        #expect(vm.validationMessage == "")
    }

    @Test func resetDoesNotClearItemsList() {
        let vm = InputViewModel()
        vm.addItem()
        vm.reset()
        #expect(vm.items.count == 2)
    }

    // MARK: itemCountLabel

    @Test func itemCountLabelSingularWhenOneItem() {
        let vm = InputViewModel()
        #expect(vm.itemCountLabel == "1 item")
    }

    @Test func itemCountLabelPluralWhenTwoItems() {
        let vm = InputViewModel()
        vm.addItem()
        #expect(vm.itemCountLabel == "2 items")
    }

    @Test func itemCountLabelCountsItemsWithEmptyNameOrPositivePrice() {
        let vm = InputViewModel()
        vm.addItem()
        vm.items[0].name = "Coffee"
        vm.items[0].priceInCents = 300
        vm.items[1].name = ""
        vm.items[1].priceInCents = 0
        // Item 0: name not empty AND price > 0 → price > 0 satisfies condition
        // Item 1: name is empty → satisfies condition
        #expect(vm.itemCountLabel == "2 items")
    }
}

// MARK: - Report View Model

@Suite("Report View Model")
@MainActor
struct ReportViewModelSuite {

    private func makeResult(
        balance: Int = 1000,
        items: [SelectedItem] = [],
        quality: MatchQuality = .perfect,
        allSelections: [[SelectedItem]] = [[]]
    ) -> OptimizationResult {
        OptimizationResult(
            balanceInCents: balance,
            selectedItems: items,
            matchQuality: quality,
            allSelections: allSelections
        )
    }

    private func selected(name: String = "Item", cents: Int = 100, qty: Int = 1) -> SelectedItem {
        SelectedItem(item: ShoppingItem(name: name, priceInCents: cents), quantity: qty)
    }

    // MARK: matchLabel

    @Test func matchLabelIsPerfectMatchForPerfectQuality() {
        let vm = ReportViewModel(result: makeResult(quality: .perfect))
        #expect(vm.matchLabel == "Perfect Match")
    }

    @Test func matchLabelIsBestPossibleForPartialQuality() {
        let vm = ReportViewModel(result: makeResult(quality: .partial(remainingCents: 50)))
        #expect(vm.matchLabel == "Best Possible")
    }

    @Test func matchLabelIsNoSolutionForNoSolutionQuality() {
        let vm = ReportViewModel(result: makeResult(quality: .noSolution))
        #expect(vm.matchLabel == "No Solution")
    }

    // MARK: isPerfectMatch

    @Test func isPerfectMatchOnlyTrueForPerfectQuality() {
        #expect(ReportViewModel(result: makeResult(quality: .perfect)).isPerfectMatch)
        #expect(!ReportViewModel(result: makeResult(quality: .partial(remainingCents: 10))).isPerfectMatch)
        #expect(!ReportViewModel(result: makeResult(quality: .noSolution)).isPerfectMatch)
    }

    // MARK: currentItems

    @Test func currentItemsDefaultsToFirstSelectionAtIndexZero() {
        let a = selected(name: "A", cents: 300)
        let b = selected(name: "B", cents: 200)
        let vm = ReportViewModel(result: makeResult(allSelections: [[a], [b]]))
        #expect(vm.currentItems == [a])
    }

    @Test func currentItemsUpdatesWhenIndexChanges() {
        let a = selected(name: "A", cents: 300)
        let b = selected(name: "B", cents: 200)
        let vm = ReportViewModel(result: makeResult(allSelections: [[a], [b]]))
        vm.selectedComboIndex = 1
        #expect(vm.currentItems == [b])
    }

    @Test func currentItemsClampsNegativeIndexToZero() {
        let a = selected(cents: 300)
        let vm = ReportViewModel(result: makeResult(allSelections: [[a]]))
        vm.selectedComboIndex = -999
        #expect(vm.currentItems == [a])
    }

    @Test func currentItemsClampsIntMaxIndexToLastSelection() {
        let a = selected(name: "A", cents: 300)
        let b = selected(name: "B", cents: 200)
        let vm = ReportViewModel(result: makeResult(allSelections: [[a], [b]]))
        vm.selectedComboIndex = Int.max
        #expect(vm.currentItems == [b])
    }

    @Test func currentItemsFallsBackToSelectedItemsWhenAllSelectionsIsEmpty() {
        let a = selected(cents: 500)
        let result = OptimizationResult(
            balanceInCents: 500,
            selectedItems: [a],
            matchQuality: .perfect,
            allSelections: []
        )
        let vm = ReportViewModel(result: result)
        #expect(vm.currentItems == [a])
    }

    // MARK: Formatting

    @Test func originalBalanceFormattedAsDollarAmount() {
        let vm = ReportViewModel(result: makeResult(balance: 1099))
        #expect(vm.originalBalanceForDisplay == "$10.99")
    }

    @Test func totalSpentReflectsCurrentComboNotPrimary() {
        let a = selected(name: "A", cents: 300, qty: 2) // $6.00
        let b = selected(name: "B", cents: 100, qty: 1) // $1.00
        let vm = ReportViewModel(result: makeResult(balance: 700, allSelections: [[a], [b]]))

        vm.selectedComboIndex = 0
        #expect(vm.totalSpentForDisplay == "$6.00")

        vm.selectedComboIndex = 1
        #expect(vm.totalSpentForDisplay == "$1.00")
    }

    @Test func remainingBalanceReflectsCurrentComboSpend() {
        let a = selected(cents: 600) // spends $6.00
        let b = selected(cents: 100) // spends $1.00
        let vm = ReportViewModel(result: makeResult(
            balance: 700,
            quality: .partial(remainingCents: 100),
            allSelections: [[a], [b]]
        ))

        vm.selectedComboIndex = 0
        #expect(vm.remainingBalanceForDisplay == "$1.00")

        vm.selectedComboIndex = 1
        #expect(vm.remainingBalanceForDisplay == "$6.00")
    }

    // MARK: hasMultipleCombinations

    @Test func hasMultipleCombinationsFalseForSingleSelection() {
        let vm = ReportViewModel(result: makeResult(allSelections: [[selected()]]))
        #expect(!vm.hasMultipleCombinations)
    }

    @Test func hasMultipleCombinationsTrueForTwoOrMoreSelections() {
        let vm = ReportViewModel(result: makeResult(allSelections: [[selected(name: "A")], [selected(name: "B")]]))
        #expect(vm.hasMultipleCombinations)
    }

    // MARK: combinationSelectorTitle

    @Test func combinationSelectorTitleIsEmptyForSingleSelection() {
        let vm = ReportViewModel(result: makeResult(allSelections: [[selected()]]))
        #expect(vm.combinationSelectorTitle == "")
    }

    @Test func combinationSelectorTitleShowsCurrentIndexAndTotal() {
        let vm = ReportViewModel(result: makeResult(allSelections: [
            [selected(name: "A")],
            [selected(name: "B")],
            [selected(name: "C")]
        ]))
        #expect(vm.combinationSelectorTitle == "Option 1 of 3")
        vm.selectedComboIndex = 2
        #expect(vm.combinationSelectorTitle == "Option 3 of 3")
    }

    // MARK: summaryMessage

    @Test func summaryMessageForPerfectMatchMentionsZeroBalance() {
        let vm = ReportViewModel(result: makeResult(quality: .perfect))
        #expect(vm.summaryMessage.contains("$0.00"))
    }

    @Test func summaryMessageForNoSolutionMentionsNoItems() {
        let vm = ReportViewModel(result: makeResult(quality: .noSolution))
        #expect(vm.summaryMessage.lowercased().contains("none"))
    }

    @Test func summaryMessageForPartialReflectsCurrentComboRemainingBalance() {
        let a = selected(cents: 600)
        let vm = ReportViewModel(result: makeResult(
            balance: 700,
            quality: .partial(remainingCents: 600),
            allSelections: [[a]]
        ))
        // currentRemainingCents = 700 - 600 = 100 → $1.00
        #expect(vm.summaryMessage.contains("$1.00"))
    }

    @Test func summaryMessageForPartialWithZeroCurrentRemainingStillShowsZero() {
        // Combo spends the full balance even though quality is .partial
        let a = selected(cents: 700)
        let vm = ReportViewModel(result: makeResult(
            balance: 700,
            quality: .partial(remainingCents: 300),
            allSelections: [[a]]
        ))
        // currentRemainingCents = 700 - 700 = 0 → $0.00
        #expect(vm.summaryMessage.contains("$0.00"))
    }
}

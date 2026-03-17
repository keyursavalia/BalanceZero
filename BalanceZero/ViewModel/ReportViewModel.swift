import Foundation
import Combine

@MainActor
final class ReportViewModel: ObservableObject {

    let result: OptimizationResult
    @Published var selectedComboIndex: Int = 0

    init(result: OptimizationResult) {
        self.result = result
    }

    var remainingBalanceForDisplay: String {
        formatCents(currentRemainingCents)
    }
    
    var originalBalanceForDisplay: String {
        formatCents(result.balanceInCents)
    }
    
    var totalSpentForDisplay: String {
        let total = currentItems.reduce(0) { $0 + $1.totalCents }
        return formatCents(total)
    }

    var matchLabel: String {
        switch result.matchQuality {
        case .perfect:             return "Perfect Match"
        case .partial:             return "Best Possible"
        case .noSolution:          return "No Solution"
        }
    }

    var isPerfectMatch: Bool {
        result.matchQuality == .perfect
    }
    
    var hasMultipleCombinations: Bool {
        result.allSelections.count > 1
    }
    
    var combinationSelectorTitle: String {
        guard hasMultipleCombinations else { return "" }
        return "Option \(selectedComboIndex + 1) of \(result.allSelections.count)"
    }
    
    var currentItems: [SelectedItem] {
        guard !result.allSelections.isEmpty else {
            return result.selectedItems
        }
        let clampedIndex = max(0, min(selectedComboIndex, result.allSelections.count - 1))
        return result.allSelections[clampedIndex]
    }
    
    private var currentRemainingCents: Int {
        let total = currentItems.reduce(0) { $0 + $1.totalCents }
        return result.balanceInCents - total
    }

    var summaryMessage: String {
        switch result.matchQuality {
        case .perfect:
            return "Buying these exact items will leave your card with a $0.00 balance."
        case .partial(let cents):
            let formatted = formatCents(currentRemainingCents)
            return "This is the closest combination. Your card will still have \(formatted) remaining."
        case .noSolution:
            return "None of the items fit within your balance. Try adding smaller items."
        }
    }

    private func formatCents(_ cents: Int) -> String {
        let decimal = Decimal(cents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: decimal as NSDecimalNumber) ?? "$0.00"
    }
}

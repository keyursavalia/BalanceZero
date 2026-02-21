import Foundation
import Combine

@MainActor
final class ReportViewModel: ObservableObject {

    let result: OptimizationResult

    init(result: OptimizationResult) {
        self.result = result
    }

    var remainingBalanceForDisplay: String {
        formatCents(result.remainingCents)
    }

    var originalBalanceForDisplay: String {
        formatCents(result.balanceInCents)
    }

    var totalSpentForDisplay: String {
        formatCents(result.totalCentsSpent)
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

    var summaryMessage: String {
        switch result.matchQuality {
        case .perfect:
            return "Buying these exact items will leave your card with a $0.00 balance."
        case .partial(let cents):
            let formatted = formatCents(cents)
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

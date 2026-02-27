import SwiftUI

/// Reusable price input with modern currency UX: digits only, fixed period, max 5 digits (2 decimals).
struct CurrencyPriceField: View {
    @Binding var priceInCents: Int

    @State private var displayText: String = "0.00"

    private var hasValue: Bool { priceInCents > 0 || displayText != "0.00" }

    var body: some View {
        HStack(spacing: 2) {
            Text("$")
                .foregroundStyle(hasValue ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.5))
                .font(.system(size: 15, weight: .semibold))

            TextField("0.00", text: $displayText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(hasValue ? AppTheme.textPrimary : AppTheme.textSecondary)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 56, alignment: .trailing)
                .onChange(of: displayText) { _, newValue in
                    processInput(newValue)
                }
        }
        .onAppear { syncFromCents() }
        .onChange(of: priceInCents) { _, _ in syncFromCents() }
    }

    private func processInput(_ raw: String) {
        let digits = CurrencyInputHelper.extractDigits(from: raw)
        let formatted = CurrencyInputHelper.formatDigitsToAmount(digits)
        displayText = formatted
        priceInCents = CurrencyInputHelper.centsFromFormatted(formatted)
    }

    private func syncFromCents() {
        displayText = CurrencyInputHelper.formattedFromCents(priceInCents)
    }
}

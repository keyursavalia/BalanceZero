import SwiftUI

struct BalanceInputCard: View {
    @Binding var balanceText: String
    let balanceInCents: Int
    @FocusState private var isFocused: Bool

    @State private var displayText: String = "0.00"
    private var hasValue: Bool { !balanceText.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CARD BALANCE")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                TextField("0.00", text: $displayText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(hasValue ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .onChange(of: displayText) { _, newValue in
                        processBalanceInput(newValue)
                    }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .onTapGesture { isFocused = true }
        .onAppear { syncDisplayFromBalance() }
        .onChange(of: balanceText) { _, newValue in
            if CurrencyInputHelper.formatDigitsToAmount(CurrencyInputHelper.extractDigits(from: newValue)) != newValue {
                syncDisplayFromBalance()
            }
        }
    }

    private func processBalanceInput(_ raw: String) {
        let digits = CurrencyInputHelper.extractDigits(from: raw)
        let formatted = CurrencyInputHelper.formatDigitsToAmount(digits)
        displayText = formatted
        balanceText = formatted
    }

    private func syncDisplayFromBalance() {
        if balanceText.isEmpty {
            displayText = "0.00"
        } else {
            let digits = CurrencyInputHelper.extractDigits(from: balanceText)
            let formatted = CurrencyInputHelper.formatDigitsToAmount(digits)
            displayText = formatted
            if balanceText != formatted {
                balanceText = formatted
            }
        }
    }
}

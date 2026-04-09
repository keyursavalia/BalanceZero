import SwiftUI

struct BalanceInputCard: View {
    @Binding var balanceText: String
    let balanceInCents: Int
    @FocusState private var isFocused: Bool
    @State private var displayText: String = "0.00"

    private var hasValue: Bool { balanceInCents > 0 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative ambient light blob
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 160, height: 160)
                .blur(radius: 30)
                .offset(x: 50, y: -60)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                Text("CARD BALANCE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(Color.white.opacity(0.65))

                Spacer().frame(height: 14)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(Color.white.opacity(hasValue ? 1.0 : 0.35))

                    TextField("0.00", text: $displayText)
                        .font(.system(size: 52, weight: .heavy))
                        .foregroundStyle(Color.white.opacity(hasValue ? 1.0 : 0.35))
                        .tint(.white)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .minimumScaleFactor(0.35)
                        .lineLimit(1)
                        .onChange(of: displayText) { _, newValue in
                            processBalanceInput(newValue)
                        }
                }

                Spacer().frame(height: 10)

                Text(hasValue ? "Ready to distribute" : "Tap to enter your balance")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .animation(.easeInOut(duration: 0.18), value: hasValue)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryContainer],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG, style: .continuous)
        )
        .shadow(color: AppTheme.primary.opacity(0.28), radius: 20, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG, style: .continuous))
        .onTapGesture { isFocused = true }
        .onAppear { syncDisplayFromBalance() }
        .onChange(of: balanceText) { _, _ in
            let formatted = CurrencyInputHelper.formatDigitsToAmount(
                CurrencyInputHelper.extractDigits(from: balanceText)
            )
            if displayText != formatted { syncDisplayFromBalance() }
        }
    }

    private func processBalanceInput(_ raw: String) {
        let digits = CurrencyInputHelper.extractDigits(from: raw)
        let formatted = CurrencyInputHelper.formatDigitsToAmount(digits)
        if displayText != formatted { displayText = formatted }
        balanceText = formatted
    }

    private func syncDisplayFromBalance() {
        if balanceText.isEmpty {
            displayText = "0.00"
        } else {
            let digits = CurrencyInputHelper.extractDigits(from: balanceText)
            let formatted = CurrencyInputHelper.formatDigitsToAmount(digits)
            displayText = formatted
            if balanceText != formatted { balanceText = formatted }
        }
    }
}

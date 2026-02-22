import SwiftUI

struct BalanceInputCard: View {
    @Binding var balanceText: String
    let balanceInCents: Int
    @FocusState private var isFocused: Bool

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

                TextField("0.00", text: $balanceText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(balanceInCents > 0 ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .onTapGesture { isFocused = true }
    }
}

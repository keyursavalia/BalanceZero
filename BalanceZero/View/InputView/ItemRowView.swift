import SwiftUI

struct ItemRowView: View {
    @Binding var item: ShoppingItem

    @State private var priceText: String = ""
    @FocusState private var nameFocused: Bool
    @FocusState private var priceFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Item Name")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)

                TextField("New Item...", text: $item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($nameFocused)
                    .submitLabel(.next)
                    .onSubmit { priceFocused = true }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Price")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 2) {
                    Text("$")
                        .foregroundStyle(item.priceInCents > 0 ? AppTheme.textSecondary : AppTheme.textSecondary.opacity(0.5))
                        .font(.system(size: 15))

                    TextField("0.00", text: $priceText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(item.priceInCents > 0 ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($priceFocused)
                        .frame(minWidth: 60, maxWidth: 90)
                        .onChange(of: priceText) { _, newValue in
                            commitPrice(newValue)
                        }
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .onAppear {
            if item.priceInCents > 0 {
                priceText = formatCentsToString(item.priceInCents)
            }
        }
    }

    private func commitPrice(_ text: String) {
        let cleaned = text.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        if let value = Decimal(string: cleaned) {
            item.priceInCents = max(0, NSDecimalNumber(decimal: value * 100).intValue)
        } else {
            item.priceInCents = 0
        }
    }

    private func formatCentsToString(_ cents: Int) -> String {
        let value = Decimal(cents) / 100
        return "\(value)"
    }
}

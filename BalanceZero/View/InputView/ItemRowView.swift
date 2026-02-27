import SwiftUI

struct ItemRowView: View {
    @Binding var item: ShoppingItem

    /// Display string: "0.00" when empty (grey placeholder), otherwise "X.XX". Period is fixed; max 5 digits.
    @State private var priceDisplayText: String = "0.00"
    @FocusState private var nameFocused: Bool
    @FocusState private var priceFocused: Bool

    private var priceHasValue: Bool { item.priceInCents > 0 || priceDisplayText != "0.00" }

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

            VStack(alignment: .center, spacing: 4) {
                Text("Qty")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 6) {
                    Button {
                        if item.mandatoryQuantity > 0 {
                            item.mandatoryQuantity -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(item.mandatoryQuantity > 0 ? AppTheme.accent : AppTheme.textSecondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)

                    Text("\(item.mandatoryQuantity)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(minWidth: 24, alignment: .center)

                    Button {
                        item.mandatoryQuantity += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }

            VStack(alignment: .trailing, spacing: 4) {
                Text("Price")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(alignment: .center, spacing: 2) {
                    Text("$")
                        .foregroundStyle(priceHasValue ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.5))
                        .font(.system(size: 17, weight: .semibold))

                    TextField("0.00", text: $priceDisplayText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(priceHasValue ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($priceFocused)
                        .frame(width: 56, alignment: .trailing)
                        .onChange(of: priceDisplayText) { _, newValue in
                            processPriceInput(newValue)
                        }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(width: 76, alignment: .trailing)
        }
        .padding(20)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .onAppear { syncPriceDisplayFromItem() }
        .onChange(of: item.priceInCents) { _, _ in
            syncPriceDisplayFromItem()
        }
    }

    private func extractDigits(from s: String) -> String {
        String(s.filter { $0.isNumber }.prefix(5))
    }

    private func formatDigitsToPrice(_ digits: String) -> String {
        if digits.isEmpty { return "0.00" }
        let padded = String(repeating: "0", count: max(0, 3 - digits.count)) + digits
        let centsPart = String(padded.suffix(2))
        let dollarsPart = String(padded.dropLast(2))
        let trimmedDollars = dollarsPart.drop(while: { $0 == "0" })
        return "\(trimmedDollars.isEmpty ? "0" : String(trimmedDollars)).\(centsPart)"
    }

    private func processPriceInput(_ raw: String) {
        let digits = extractDigits(from: raw)
        let formatted = formatDigitsToPrice(digits)
        priceDisplayText = formatted
        if let value = Decimal(string: formatted) {
            item.priceInCents = max(0, NSDecimalNumber(decimal: value * 100).intValue)
        } else {
            item.priceInCents = 0
        }
    }

    private func syncPriceDisplayFromItem() {
        if item.priceInCents == 0 {
            priceDisplayText = "0.00"
        } else {
            let digits = String(item.priceInCents)
            let padded = String(repeating: "0", count: max(0, 3 - digits.count)) + digits
            let centsPart = String(padded.suffix(2))
            let dollarsPart = String(padded.dropLast(2))
            let trimmedDollars = dollarsPart.drop(while: { $0 == "0" })
            priceDisplayText = "\(trimmedDollars.isEmpty ? "0" : String(trimmedDollars)).\(centsPart)"
        }
    }
}

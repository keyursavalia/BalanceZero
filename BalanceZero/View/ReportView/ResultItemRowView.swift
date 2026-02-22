import SwiftUI

struct ResultItemRowView: View {
    let selected: SelectedItem

    private var icon: String {
        // Heuristic icon mapping based on common item names
        let name = selected.item.name.lowercased()
        if name.contains("coffee") || name.contains("espresso")    { return "cup.and.saucer" }
        if name.contains("grocer") || name.contains("food")        { return "cart" }
        if name.contains("tax")                                     { return "doc.text" }
        if name.contains("gas") || name.contains("fuel")           { return "fuelpump" }
        if name.contains("book") || name.contains("note")          { return "book" }
        return "bag"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.background)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(selected.item.name.isEmpty ? "Item" : selected.item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                if selected.quantity > 1 {
                    Text("x\(selected.quantity) @ \(formattedUnitPrice)")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            Text(formattedTotal)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.innerCornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var formattedTotal: String {
        format(cents: selected.totalCents)
    }

    private var formattedUnitPrice: String {
        format(cents: selected.item.priceInCents)
    }

    private func format(cents: Int) -> String {
        let decimal = Decimal(cents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: decimal as NSDecimalNumber) ?? "$0.00"
    }
}

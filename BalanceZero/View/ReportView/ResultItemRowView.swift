import SwiftUI

struct ResultItemRowView: View {
    let selected: SelectedItem

    private var icon: String {
        let name = selected.item.name.lowercased()
        if name.contains("coffee") || name.contains("espresso") || name.contains("latte") { return "cup.and.saucer.fill" }
        if name.contains("gas") || name.contains("fuel")                                  { return "fuelpump.fill" }
        if name.contains("book") || name.contains("novel")                                { return "book.fill" }
        if name.contains("food") || name.contains("grocer") || name.contains("meal")     { return "cart.fill" }
        if name.contains("milk") || name.contains("drink") || name.contains("juice")     { return "drop.fill" }
        if name.contains("bread") || name.contains("bak")                                 { return "birthday.cake.fill" }
        return "bag.fill"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon bubble
            ZStack {
                Circle()
                    .fill(AppTheme.surfaceHigh)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(selected.item.name.isEmpty ? "Item" : selected.item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)

                if selected.quantity > 1 {
                    Text("×\(selected.quantity) @ \(formattedUnitPrice)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.outline)
                }
            }

            Spacer()

            Text(formattedTotal)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.onSurface)
        }
        .padding(16)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var formattedTotal: String { format(cents: selected.totalCents) }
    private var formattedUnitPrice: String { format(cents: selected.item.priceInCents) }

    private func format(cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: (Decimal(cents) / 100) as NSDecimalNumber) ?? "$0.00"
    }
}

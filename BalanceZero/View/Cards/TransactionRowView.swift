import SwiftUI

struct TransactionRowView: View {
    let transaction: CardTransaction

    private var amountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return "-" + (formatter.string(from: (Decimal(transaction.amountInCents) / 100) as NSDecimalNumber) ?? "$0.00")
    }

    private var dateFormatted: String {
        let cal = Calendar.current
        let now = Date()
        if cal.isDateInToday(transaction.createdAt) {
            let f = DateFormatter()
            f.timeStyle = .short
            return "Today · " + f.string(from: transaction.createdAt)
        } else if cal.isDateInYesterday(transaction.createdAt) {
            let f = DateFormatter()
            f.timeStyle = .short
            return "Yesterday · " + f.string(from: transaction.createdAt)
        } else {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: transaction.createdAt)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon bubble
            ZStack {
                Circle()
                    .fill(AppTheme.surfaceHigh)
                    .frame(width: 44, height: 44)
                Image(systemName: iconForNote(transaction.note))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }

            // Note + date
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.note.isEmpty ? "Manual transaction" : transaction.note)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)
                    .lineLimit(1)

                Text(dateFormatted)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.outline)
            }

            Spacer()

            // Amount
            Text(amountFormatted)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "b71c1c"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            AppTheme.surfaceLowest,
            in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
        )
        .shadow(color: AppTheme.onSurface.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // Maps note keywords to an appropriate icon
    private func iconForNote(_ note: String) -> String {
        let lower = note.lowercased()
        if lower.contains("coffee") || lower.contains("espresso") || lower.contains("cafe") { return "cup.and.saucer.fill" }
        if lower.contains("gas") || lower.contains("fuel") || lower.contains("petrol") { return "fuelpump.fill" }
        if lower.contains("grocery") || lower.contains("groceries") || lower.contains("supermarket") { return "cart.fill" }
        if lower.contains("food") || lower.contains("meal") || lower.contains("restaurant") || lower.contains("eat") { return "fork.knife" }
        if lower.contains("book") || lower.contains("library") { return "book.fill" }
        if lower.contains("transport") || lower.contains("uber") || lower.contains("lyft") || lower.contains("taxi") { return "car.fill" }
        if lower.contains("pharma") || lower.contains("medicine") || lower.contains("drug") { return "cross.fill" }
        if lower.contains("shop") || lower.contains("store") || lower.contains("mall") { return "bag.fill" }
        if lower.contains("online") || lower.contains("amazon") || lower.contains("delivery") { return "shippingbox.fill" }
        return "creditcard.fill"
    }
}

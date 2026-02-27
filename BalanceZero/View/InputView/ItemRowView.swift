import SwiftUI

struct ItemRowView: View {
    @Binding var item: ShoppingItem

    @FocusState private var nameFocused: Bool

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
                    .onSubmit { }
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

                CurrencyPriceField(priceInCents: $item.priceInCents)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(width: 76, alignment: .trailing)
        }
        .padding(20)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

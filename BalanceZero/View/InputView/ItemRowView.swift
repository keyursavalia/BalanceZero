import SwiftUI

struct ItemRowView: View {
    @Binding var item: ShoppingItem
    var isLastRow: Bool
    var onDelete: () -> Void
    var onPriceBecameNonZero: (() -> Void)?

    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                if item.priceInCents > 0 {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

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

            // Subtle quantity-constraint hint when user has set a quantity
            if item.mandatoryQuantity > 0 {
                quantityConstraintHint
            }
        }
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .onChange(of: item.priceInCents) { oldValue, newValue in
            if oldValue == 0 && newValue > 0, isLastRow {
                onPriceBecameNonZero?()
            }
        }
    }

    @ViewBuilder
    private var quantityConstraintHint: some View {
        HStack(spacing: 8) {
            Text("Include:")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)

            Picker("Quantity constraint", selection: $item.quantityConstraint) {
                Text("Exactly \(item.mandatoryQuantity)").tag(QuantityConstraint.exact)
                Text("At least \(item.mandatoryQuantity)").tag(QuantityConstraint.minimum)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .padding(.top, 4)
    }
}

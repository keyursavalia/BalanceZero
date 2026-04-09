import SwiftUI

struct ItemRowView: View {
    @Binding var item: ShoppingItem
    var isLastRow: Bool
    var onDelete: () -> Void
    var onPriceBecameNonZero: (() -> Void)?

    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Delete button — only shown when item has a price
                if item.priceInCents > 0 {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.outline)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.surfaceHigh, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }

                // Name field
                TextField("New item...", text: $item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)
                    .focused($nameFocused)
                    .submitLabel(.next)

                Spacer(minLength: 8)

                // Price field — right-aligned pill
                CurrencyPriceField(priceInCents: $item.priceInCents)
                    .frame(width: 78, alignment: .trailing)

                // Quantity stepper pill
                quantityStepper
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: item.priceInCents > 0)

            // Constraint picker — slides in when a quantity is set
            if item.mandatoryQuantity > 0 {
                constraintPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.05), radius: 8, x: 0, y: 3)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: item.mandatoryQuantity > 0)
        .onChange(of: item.priceInCents) { oldValue, newValue in
            if oldValue == 0 && newValue > 0, isLastRow {
                onPriceBecameNonZero?()
            }
        }
    }

    // MARK: - Quantity Stepper

    private var quantityStepper: some View {
        HStack(spacing: 0) {
            Button {
                if item.mandatoryQuantity > 0 {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        item.mandatoryQuantity -= 1
                    }
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(item.mandatoryQuantity > 0 ? AppTheme.onSurface : AppTheme.outlineVariant)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .disabled(item.mandatoryQuantity == 0)

            Text("\(item.mandatoryQuantity)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.onSurface)
                .frame(minWidth: 22, alignment: .center)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.25), value: item.mandatoryQuantity)

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    item.mandatoryQuantity += 1
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .background(AppTheme.surfaceHigh, in: Capsule())
    }

    // MARK: - Constraint Picker

    private var constraintPicker: some View {
        HStack(spacing: 8) {
            Text("Include:")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.outline)
                .tracking(0.5)

            Picker("Constraint", selection: $item.quantityConstraint) {
                Text("Exactly \(item.mandatoryQuantity)").tag(QuantityConstraint.exact)
                Text("At least \(item.mandatoryQuantity)").tag(QuantityConstraint.minimum)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .padding(.top, 4)
    }
}

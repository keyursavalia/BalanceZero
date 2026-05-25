import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let card: Card

    @State private var amountDigits: String = ""
    @State private var note: String = ""
    @FocusState private var noteFocused: Bool

    private var formattedAmount: String {
        CurrencyInputHelper.formatDigitsToAmount(amountDigits)
    }

    private var amountInCents: Int {
        CurrencyInputHelper.centsFromFormatted(formattedAmount)
    }

    private var canLog: Bool { amountInCents > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        amountSection
                        noteSection
                        balancePreview
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { logBar }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navToolbar }
        }
    }

    // MARK: - Amount section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("TRANSACTION AMOUNT")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("$")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(amountInCents > 0 ? AppTheme.primary : AppTheme.outlineVariant)

                LargeTransactionField(
                    digits: $amountDigits,
                    maxDigits: 7,
                    formattedValue: formattedAmount
                )
                .frame(maxWidth: .infinity)
                .frame(height: 64)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                AppTheme.surfaceLowest,
                in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG, style: .continuous)
            )
            .shadow(color: AppTheme.primary.opacity(amountInCents > 0 ? 0.08 : 0), radius: 10, x: 0, y: 4)
            .animation(.easeInOut(duration: 0.2), value: amountInCents > 0)
        }
    }

    // MARK: - Note section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("NOTE (OPTIONAL)")
            TextField("e.g. Groceries, Gas station...", text: $note)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(AppTheme.onSurface)
                .padding(16)
                .background(
                    AppTheme.surfaceLowest,
                    in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                )
                .focused($noteFocused)
                .autocorrectionDisabled()
        }
    }

    // MARK: - Balance preview

    private var balancePreview: some View {
        let newBalance = card.currentBalanceInCents - amountInCents
        return VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    label("CURRENT BALANCE")
                    Text(formatCents(card.currentBalanceInCents))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.onSurface)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.outlineVariant)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    label("AFTER THIS SPEND")
                    Text(formatCents(newBalance))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(newBalance < 0 ? Color(hex: "b71c1c") : AppTheme.primary)
                }
            }
            .padding(20)
        }
        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .animation(.easeInOut(duration: 0.15), value: amountInCents)
    }

    // MARK: - Log bar

    private var logBar: some View {
        Button(action: logTransaction) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("Log Transaction")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                canLog
                    ? LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer],
                                     startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [AppTheme.outlineVariant, AppTheme.outlineVariant],
                                     startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous)
            )
            .shadow(color: AppTheme.primary.opacity(canLog ? 0.22 : 0), radius: 16, x: 0, y: 6)
        }
        .disabled(!canLog)
        .animation(.easeInOut(duration: 0.2), value: canLog)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var navToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text("Log Transaction")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(AppTheme.primary)
                Text(card.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.outline)
            }
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.onSurfaceVariant)
        }
    }

    // MARK: - Helpers

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.5)
            .foregroundStyle(AppTheme.outline)
    }

    private func logTransaction() {
        guard canLog else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let transaction = CardTransaction(
            note: trimmedNote.isEmpty ? "Manual transaction" : trimmedNote,
            amountInCents: amountInCents,
            card: card
        )
        modelContext.insert(transaction)
        try? modelContext.save()
        dismiss()
    }

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: (Decimal(cents) / 100) as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Large transaction digit field

private struct LargeTransactionField: UIViewRepresentable {
    @Binding var digits: String
    let maxDigits: Int
    let formattedValue: String

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .decimalPad
        field.textAlignment = .left
        field.font = UIFont.systemFont(ofSize: 46, weight: .heavy)
        field.adjustsFontSizeToFitWidth = true
        field.minimumFontSize = 24
        field.tintColor = UIColor(AppTheme.primary)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.delegate = context.coordinator
        field.text = formattedValue
        field.becomeFirstResponder()
        updateColor(field)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != formattedValue { uiView.text = formattedValue }
        updateColor(uiView)
        pinToEnd(uiView)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func updateColor(_ f: UITextField) {
        let hasCents = CurrencyInputHelper.centsFromFormatted(formattedValue) > 0
        f.textColor = UIColor(hasCents ? AppTheme.primary : AppTheme.outlineVariant)
    }

    private func pinToEnd(_ f: UITextField) {
        guard f.isFirstResponder else { return }
        DispatchQueue.main.async {
            let end = f.endOfDocument
            f.selectedTextRange = f.textRange(from: end, to: end)
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: LargeTransactionField
        init(_ p: LargeTransactionField) { self.parent = p }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = parent.digits
            let updated: String
            if string.isEmpty {
                updated = current.isEmpty ? "" : String(current.dropLast())
            } else {
                let filtered = string.filter { $0.isNumber }
                guard !filtered.isEmpty else { return false }
                updated = current + filtered
            }
            parent.digits = CurrencyInputHelper.extractDigits(from: updated, maxDigits: parent.maxDigits)
            return false
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async { [weak textField] in
                guard let f = textField, f.isFirstResponder else { return }
                let end = f.endOfDocument
                if f.selectedTextRange != f.textRange(from: end, to: end) {
                    f.selectedTextRange = f.textRange(from: end, to: end)
                }
            }
        }
    }
}

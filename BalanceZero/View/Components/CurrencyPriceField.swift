import SwiftUI
import UIKit

struct CurrencyPriceField: View {
    @Binding var priceInCents: Int
    @State private var displayText: String = "0.00"

    private var hasValue: Bool { priceInCents > 0 }

    var body: some View {
        HStack(spacing: 2) {
            Text("$")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(hasValue ? AppTheme.onSurface : AppTheme.outlineVariant)

            TrailingCursorTextField(
                text: $displayText,
                hasValue: hasValue,
                onTextChanged: processInput
            )
            .frame(width: 56, height: 26)
        }
        .onAppear { syncFromCents() }
        .onChange(of: priceInCents) { _, _ in syncFromCents() }
    }

    private func processInput(_ raw: String) {
        let digits = CurrencyInputHelper.extractDigits(from: raw)
        let formatted = CurrencyInputHelper.formatDigitsToAmount(digits)
        if displayText != formatted { displayText = formatted }
        priceInCents = CurrencyInputHelper.centsFromFormatted(formatted)
    }

    private func syncFromCents() {
        let formatted = CurrencyInputHelper.formattedFromCents(priceInCents)
        if displayText != formatted { displayText = formatted }
    }
}

// MARK: - UIViewRepresentable — keeps cursor pinned to the trailing end at all times

private struct TrailingCursorTextField: UIViewRepresentable {
    @Binding var text: String
    let hasValue: Bool
    let onTextChanged: (String) -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .decimalPad
        field.textAlignment = .right
        field.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        field.tintColor = UIColor(AppTheme.primary)
        field.delegate = context.coordinator
        field.text = text
        field.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        updateTextColor(field)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        updateTextColor(uiView)
        // Repin cursor to end whenever the view updates
        moveToEnd(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func updateTextColor(_ field: UITextField) {
        field.textColor = hasValue
            ? UIColor(AppTheme.onSurface)
            : UIColor(AppTheme.outline)
    }

    private func moveToEnd(_ field: UITextField) {
        guard field.isFirstResponder else { return }
        DispatchQueue.main.async {
            let end = field.endOfDocument
            field.selectedTextRange = field.textRange(from: end, to: end)
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: TrailingCursorTextField

        init(_ parent: TrailingCursorTextField) {
            self.parent = parent
        }

        // Intercept every keystroke — process through CurrencyInputHelper, return false
        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            // Ignore cursor position — always append or drop from the right end.
            let updated: String
            if string.isEmpty {
                updated = current.isEmpty ? "" : String(current.dropLast())
            } else {
                updated = current + string
            }
            parent.onTextChanged(updated)
            return false
        }

        // Called on every selection change (including taps) — pin cursor to end
        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async { [weak textField] in
                guard let field = textField, field.isFirstResponder else { return }
                let end = field.endOfDocument
                let current = field.selectedTextRange
                let targetRange = field.textRange(from: end, to: end)
                // Only update if not already at end, to avoid infinite loop
                if current != targetRange {
                    field.selectedTextRange = targetRange
                }
            }
        }
    }
}

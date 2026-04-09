import SwiftUI
import UIKit

struct BalanceInputCard: View {
    @Binding var balanceText: String
    let balanceInCents: Int
    @State private var displayText: String = "0.00"

    private var hasValue: Bool { balanceInCents > 0 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative ambient light blob
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 160, height: 160)
                .blur(radius: 30)
                .offset(x: 50, y: -60)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                Text("CARD BALANCE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(Color.white.opacity(0.65))

                Spacer().frame(height: 14)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(Color.white.opacity(hasValue ? 1.0 : 0.35))

                    BalanceTrailingTextField(
                        text: $displayText,
                        hasValue: hasValue,
                        onTextChanged: processBalanceInput
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                }

                Spacer().frame(height: 10)

                Text(hasValue ? "Ready to distribute" : "Tap to enter your balance")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .animation(.easeInOut(duration: 0.18), value: hasValue)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryContainer],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG, style: .continuous)
        )
        .shadow(color: AppTheme.primary.opacity(0.28), radius: 20, x: 0, y: 8)
        .onAppear { syncDisplayFromBalance() }
        .onChange(of: balanceText) { _, _ in
            let formatted = CurrencyInputHelper.formatDigitsToAmount(
                CurrencyInputHelper.extractDigits(from: balanceText)
            )
            if displayText != formatted { syncDisplayFromBalance() }
        }
    }

    private func processBalanceInput(_ raw: String) {
        let digits = CurrencyInputHelper.extractDigits(from: raw)
        let formatted = CurrencyInputHelper.formatDigitsToAmount(digits)
        if displayText != formatted { displayText = formatted }
        balanceText = formatted
    }

    private func syncDisplayFromBalance() {
        if balanceText.isEmpty {
            displayText = "0.00"
        } else {
            let digits = CurrencyInputHelper.extractDigits(from: balanceText)
            let formatted = CurrencyInputHelper.formatDigitsToAmount(digits)
            displayText = formatted
            if balanceText != formatted { balanceText = formatted }
        }
    }
}

// MARK: - UIViewRepresentable — large balance TextField with cursor pinned to end

private struct BalanceTrailingTextField: UIViewRepresentable {
    @Binding var text: String
    let hasValue: Bool
    let onTextChanged: (String) -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .decimalPad
        field.textAlignment = .left
        field.adjustsFontSizeToFitWidth = true
        field.minimumFontSize = 22
        field.font = UIFont.systemFont(ofSize: 52, weight: .heavy)
        field.tintColor = .white
        field.backgroundColor = .clear
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.delegate = context.coordinator
        field.text = text
        updateTextColor(field)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        updateTextColor(uiView)
        moveToEnd(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func updateTextColor(_ field: UITextField) {
        field.textColor = UIColor.white.withAlphaComponent(hasValue ? 1.0 : 0.35)
    }

    private func moveToEnd(_ field: UITextField) {
        guard field.isFirstResponder else { return }
        DispatchQueue.main.async {
            let end = field.endOfDocument
            field.selectedTextRange = field.textRange(from: end, to: end)
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BalanceTrailingTextField

        init(_ parent: BalanceTrailingTextField) {
            self.parent = parent
        }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            // Always treat input as if cursor is at the end:
            // insertion → append to end, backspace → drop last character.
            // This makes cursor position completely irrelevant.
            let updated: String
            if string.isEmpty {
                // Backspace — remove the rightmost character
                updated = current.isEmpty ? "" : String(current.dropLast())
            } else {
                // Digit typed — append to the right
                updated = current + string
            }
            parent.onTextChanged(updated)
            return false
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            // Pin cursor to trailing end on every selection change (including taps)
            DispatchQueue.main.async { [weak textField] in
                guard let field = textField, field.isFirstResponder else { return }
                let end = field.endOfDocument
                let targetRange = field.textRange(from: end, to: end)
                if field.selectedTextRange != targetRange {
                    field.selectedTextRange = targetRange
                }
            }
        }
    }
}

import SwiftUI
import SwiftData

/// Presented as a sheet (iPhone) or navigation push (iPad) for creating and editing cards.
struct CardCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    var existingCard: Card? = nil
    var onSave: ((Card) -> Void)? = nil

    @State private var cardName: String = ""
    @State private var balanceDigits: String = ""
    @State private var selectedDesign: CardDesign = .classic
    @State private var customColor: Color = Color(hex: "7b2ff7")
    @State private var customCompanyName: String = ""

    @FocusState private var nameFocused: Bool

    private var isEditing: Bool { existingCard != nil }

    private var formattedBalance: String {
        CurrencyInputHelper.formatDigitsToAmount(balanceDigits)
    }

    private var balanceInCents: Int {
        CurrencyInputHelper.centsFromFormatted(formattedBalance)
    }

    private var canSave: Bool {
        !cardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        balanceInCents > 0
    }

    private var customColorHex: String {
        customColor.toHex() ?? "7b2ff7"
    }

    var body: some View {
        // On iPad, CardCreationView is pushed into the parent NavigationStack via navigationDestination,
        // so we only wrap in NavigationStack when presented as a sheet (iPhone).
        if sizeClass == .regular {
            content
        } else {
            NavigationStack { content }
        }
    }

    private var content: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
                .dismissKeyboardOnBackgroundTap()

            ScrollView {
                VStack(spacing: 28) {
                    cardPreview
                        .padding(.top, 8)

                    formSection

                    designPickerSection

                    if selectedDesign == .custom {
                        customCardSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { saveBar }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { navToolbar }
        .onAppear { prefill() }
    }

    // MARK: - Card preview

    private var cardPreview: some View {
        CardVisualView(
            name: cardName.isEmpty ? "Card Name" : cardName,
            balanceInCents: balanceInCents,
            design: selectedDesign,
            customColorHex: selectedDesign == .custom ? customColorHex : "",
            customCompanyName: selectedDesign == .custom ? customCompanyName : ""
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedDesign)
        .animation(.easeInOut(duration: 0.15), value: cardName)
        .animation(.easeInOut(duration: 0.15), value: balanceInCents)
        .animation(.easeInOut(duration: 0.2), value: customColorHex)
        .animation(.easeInOut(duration: 0.15), value: customCompanyName)
    }

    // MARK: - Form fields

    private var formSection: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("CARD NAME")
                TextField("", text: $cardName,
                          prompt: Text("e.g. My Visa, Starbucks Gift Card")
                              .foregroundColor(AppTheme.outline))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)
                    .padding(16)
                    .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                    .autocorrectionDisabled()
                    .focused($nameFocused)
            }

            Spacer().frame(height: 20)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(isEditing ? "STARTING BALANCE (UPDATES HISTORY)" : "STARTING BALANCE")
                balanceField
            }
        }
    }

    private var balanceField: some View {
        HStack(alignment: .center, spacing: 6) {
            Text("$")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(balanceInCents > 0 ? AppTheme.primary : AppTheme.outlineVariant)

            LargeBalanceDigitField(
                digits: $balanceDigits,
                maxDigits: 7,
                placeholder: "0.00",
                formattedValue: formattedBalance
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 52)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.primary.opacity(balanceInCents > 0 ? 0.08 : 0), radius: 8, x: 0, y: 3)
    }

    // MARK: - Design picker

    private var designPickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("CARD DESIGN")
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(CardDesign.allCases, id: \.rawValue) { design in
                        designPill(design)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.never)
        }
    }

    private func designPill(_ design: CardDesign) -> some View {
        let isSelected = selectedDesign == design
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDesign = design
            }
        } label: {
            VStack(spacing: 8) {
                CardVisualView(
                    name: "",
                    balanceInCents: 0,
                    design: design,
                    isCompact: true,
                    customColorHex: design == .custom ? customColorHex : "",
                    customCompanyName: design == .custom ? customCompanyName : ""
                )
                .frame(width: 80)
                .scaleEffect(isSelected ? 1.06 : 1.0)

                Text(design.displayName)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.outline)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppTheme.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Custom card section

    private var customCardSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("CARD COLOR")
                ColorPicker("Pick a color", selection: $customColor, supportsOpacity: false)
                    .labelsHidden()
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("COMPANY / BRAND NAME (OPTIONAL)")
                TextField("", text: $customCompanyName,
                          prompt: Text("e.g. VISA, TARGET, MY BANK")
                              .foregroundColor(AppTheme.outline))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)
                    .padding(16)
                    .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                    .autocorrectionDisabled()
                    .autocapitalization(.allCharacters)
                    .onChange(of: customCompanyName) { _, new in
                        if new.count > 10 { customCompanyName = String(new.prefix(10)) }
                    }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Save bar

    private var saveBar: some View {
        Button(action: save) {
            Text(isEditing ? "Save Changes" : "Create Card")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    canSave
                        ? LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [AppTheme.outlineVariant, AppTheme.outlineVariant],
                                         startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous)
                )
                .shadow(color: AppTheme.primary.opacity(canSave ? 0.22 : 0), radius: 16, x: 0, y: 6)
        }
        .disabled(!canSave)
        .animation(.easeInOut(duration: 0.2), value: canSave)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var navToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(isEditing ? "Edit Card" : "New Card")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AppTheme.primary)
        }
        // On iPad the view is pushed via navigationDestination, so the system back button
        // already handles dismissal. Only show Cancel when presented as a sheet (iPhone).
        if sizeClass != .regular {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.5)
            .foregroundStyle(AppTheme.outline)
    }

    private func prefill() {
        guard let card = existingCard else {
            nameFocused = true
            return
        }
        cardName = card.name
        balanceDigits = CurrencyInputHelper.extractDigits(
            from: CurrencyInputHelper.formattedFromCents(card.initialBalanceInCents),
            maxDigits: 7
        )
        selectedDesign = card.design
        if !card.customColorHex.isEmpty {
            customColor = Color(hex: card.customColorHex)
        }
        customCompanyName = card.customCompanyName
    }

    private func save() {
        guard canSave else { return }
        let trimmedName = cardName.trimmingCharacters(in: .whitespacesAndNewlines)
        let colorHex = selectedDesign == .custom ? customColorHex : ""
        let companyName = selectedDesign == .custom ? customCompanyName.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        if let card = existingCard {
            card.name = trimmedName
            card.initialBalanceInCents = balanceInCents
            card.design = selectedDesign
            card.customColorHex = colorHex
            card.customCompanyName = companyName
            try? modelContext.save()
            onSave?(card)
        } else {
            let card = Card(
                name: trimmedName,
                initialBalanceInCents: balanceInCents,
                design: selectedDesign,
                customColorHex: colorHex,
                customCompanyName: companyName
            )
            modelContext.insert(card)
            try? modelContext.save()
            onSave?(card)
        }
        dismiss()
    }
}

// MARK: - Color → hex helper

private extension Color {
    func toHex() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let ri = Int(r * 255), gi = Int(g * 255), bi = Int(b * 255)
        return String(format: "%02x%02x%02x", ri, gi, bi)
    }
}

// MARK: - Large balance digit field (UIKit-backed for smooth currency input)

private struct LargeBalanceDigitField: UIViewRepresentable {
    @Binding var digits: String
    let maxDigits: Int
    let placeholder: String
    let formattedValue: String

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .decimalPad
        field.textAlignment = .left
        field.font = UIFont.systemFont(ofSize: 38, weight: .heavy)
        field.adjustsFontSizeToFitWidth = true
        field.minimumFontSize = 20
        field.tintColor = UIColor(AppTheme.primary)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.delegate = context.coordinator
        field.text = formattedValue
        updateColor(field)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != formattedValue { uiView.text = formattedValue }
        updateColor(uiView)
        pinCursorToEnd(uiView)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func updateColor(_ field: UITextField) {
        let hasCents = CurrencyInputHelper.centsFromFormatted(formattedValue) > 0
        field.textColor = UIColor(hasCents ? AppTheme.primary : AppTheme.outlineVariant)
    }

    private func pinCursorToEnd(_ field: UITextField) {
        guard field.isFirstResponder else { return }
        DispatchQueue.main.async {
            let end = field.endOfDocument
            field.selectedTextRange = field.textRange(from: end, to: end)
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: LargeBalanceDigitField
        init(_ parent: LargeBalanceDigitField) { self.parent = parent }

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

import SwiftUI
import SwiftData

struct CalculationHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel
    @Query(sort: \SavedCalculation.createdAt, order: .reverse) private var calculations: [SavedCalculation]
    @State private var selectedCalculation: SavedCalculation?
    @State private var isShowingClearAlert = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    // Groups: named cards (alphabetical) then "General" for untagged
    private var groups: [(key: String, designRawValue: String, customColorHex: String, items: [SavedCalculation])] {
        var buckets: [String: [SavedCalculation]] = [:]
        var meta: [String: (designRawValue: String, customColorHex: String)] = [:]
        for calc in calculations {
            let key = calc.cardName.isEmpty ? "" : calc.cardName
            buckets[key, default: []].append(calc)
            if !key.isEmpty && meta[key] == nil {
                meta[key] = (calc.cardDesignRawValue, calc.cardCustomColorHex)
            }
        }
        var result: [(key: String, designRawValue: String, customColorHex: String, items: [SavedCalculation])] = []
        for key in buckets.keys.filter({ !$0.isEmpty }).sorted() {
            let m = meta[key] ?? ("", "")
            result.append((key, m.designRawValue, m.customColorHex, buckets[key]!))
        }
        if let general = buckets[""] {
            result.append(("", "", "", general))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if calculations.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 28) {
                            ForEach(groups, id: \.key) { group in
                                cardGroup(group)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                        .frame(maxWidth: sizeClass == .regular ? 680 : .infinity)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { historyToolbar }
            .navigationDestination(item: $selectedCalculation) { calc in
                ReportView(vm: ReportViewModel(result: calc.optimizationResult), showsStartOver: false)
                    .environmentObject(inputVM)
            }
            .alert("Clear history?", isPresented: $isShowingClearAlert) {
                Button("Clear All", role: .destructive) { clearAllHistory() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var historyToolbar: some ToolbarContent {
        if sizeClass != .regular {
            ToolbarItem(placement: .principal) {
                Text("History")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(AppTheme.primary)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            if !calculations.isEmpty {
                Button("Clear") {
                    isShowingClearAlert = true
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
            }
        }
    }

    // MARK: - Card Group

    private func cardGroup(
        _ group: (key: String, designRawValue: String, customColorHex: String, items: [SavedCalculation])
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            cardGroupHeader(name: group.key, designRawValue: group.designRawValue, customColorHex: group.customColorHex)

            LazyVStack(spacing: 8) {
                ForEach(group.items) { calc in
                    Button {
                        selectedCalculation = calc
                    } label: {
                        CalculationRowView(calculation: calc)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteCalculation(calc)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func cardGroupHeader(name: String, designRawValue: String, customColorHex: String) -> some View {
        let design = CardDesign(rawValue: designRawValue)
        let gradientColors: [Color] = {
            if let d = design {
                if d == .custom, !customColorHex.isEmpty {
                    let base = Color(hex: customColorHex)
                    return [base.opacity(0.85), base]
                }
                return d.gradientColors
            }
            return [AppTheme.outlineVariant, AppTheme.outline]
        }()
        let label = name.isEmpty ? "General" : name
        let icon = design?.symbolName ?? "wand.and.sparkles"

        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 30, height: 30)
                Image(systemName: name.isEmpty ? "wand.and.sparkles" : icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.onSurface)

            Spacer()

            Text("\(groups.first(where: { $0.key == name })?.items.count ?? 0)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.outline)
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryFixed.opacity(0.6))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppTheme.surfaceLowest)
                            .frame(width: 72, height: 72)
                            .shadow(color: AppTheme.onSurface.opacity(0.06), radius: 10, x: 0, y: 4)
                        Image(systemName: "clock")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(AppTheme.outlineVariant)
                    }
                }

                VStack(spacing: 8) {
                    Text("No calculations yet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.onSurface)

                    Text("Your optimization results will appear here after you run your first calculation.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
            }

            Spacer().frame(height: 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func deleteCalculation(_ calc: SavedCalculation) {
        modelContext.delete(calc)
        try? modelContext.save()
    }

    private func clearAllHistory() {
        calculations.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

// MARK: - Calculation Row

struct CalculationRowView: View {
    let calculation: SavedCalculation

    private var isPerfect: Bool { calculation.matchQualityKind == "perfect" }

    private var balanceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: (Decimal(calculation.balanceInCents) / 100) as NSDecimalNumber) ?? "$0.00"
    }

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: calculation.createdAt)
    }

    private var matchLabel: String {
        switch calculation.matchQualityKind {
        case "perfect": return "Perfect"
        case "partial":  return "Partial"
        default:         return "No Solution"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(isPerfect ? AppTheme.tertiaryFixed : AppTheme.surfaceHigh)
                    .frame(width: 46, height: 46)
                Image(systemName: isPerfect ? "sparkles" : "creditcard")
                    .font(.system(size: 18))
                    .foregroundStyle(isPerfect ? AppTheme.tertiary : AppTheme.outline)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(balanceFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.onSurface)

                    Text(matchLabel)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(isPerfect ? AppTheme.tertiary : AppTheme.outline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            isPerfect ? AppTheme.tertiaryFixed : AppTheme.surfaceHighest,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                }

                Text(dateFormatted)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.outline)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.outlineVariant)
        }
        .padding(16)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

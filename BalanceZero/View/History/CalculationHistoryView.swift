import SwiftUI
import SwiftData

struct CalculationHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel
    @Query(sort: \SavedCalculation.createdAt, order: .reverse) private var calculations: [SavedCalculation]
    @State private var selectedCalculation: SavedCalculation?
    @State private var isShowingClearAlert = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if calculations.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            summaryCard
                                .padding(.top, 4)

                            listSection
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: sizeClass == .regular ? 680 : .infinity)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { historyToolbar }
            .navigationDestination(item: $selectedCalculation) { calc in
                ReportView(vm: ReportViewModel(result: calc.optimizationResult))
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
        ToolbarItem(placement: .principal) {
            Text("History")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AppTheme.primary)
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

    // MARK: - Summary Card

    private var summaryCard: some View {
        ZStack(alignment: .bottomTrailing) {
            // Decorative blob
            Circle()
                .fill(AppTheme.primary.opacity(0.06))
                .frame(width: 160, height: 160)
                .blur(radius: 30)
                .offset(x: 60, y: 30)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 8) {
                Text("CALCULATIONS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.onSurfaceVariant)

                Text(monthlySavedDisplay)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(AppTheme.primary)

                HStack(spacing: 8) {
                    Text("\(perfectMatchCount) perfect match\(perfectMatchCount == 1 ? "" : "es")")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.tertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.tertiaryFixed, in: Capsule())

                    Text("\(calculations.count) total")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG, style: .continuous))
    }

    private var monthlySavedDisplay: String {
        let now = Date()
        let calendar = Calendar.current
        let total = calculations
            .filter { calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.balanceInCents }
        return formatCents(total)
    }

    private var perfectMatchCount: Int {
        calculations.filter { $0.matchQualityKind == "perfect" }.count
    }

    // MARK: - List Section

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT CALCULATIONS")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(AppTheme.outline)
                .padding(.horizontal, 2)

            LazyVStack(spacing: 8) {
                ForEach(calculations) { calc in
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

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: (Decimal(cents) / 100) as NSDecimalNumber) ?? "$0.00"
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

import SwiftUI
import SwiftData

struct CalculationHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var inputVM: InputViewModel
    @Query(sort: \SavedCalculation.createdAt, order: .reverse) private var calculations: [SavedCalculation]
    @State private var selectedCalculation: SavedCalculation?
    @State private var isShowingClearAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if calculations.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(calculations) { calc in
                            Button {
                                selectedCalculation = calc
                            } label: {
                                CalculationRowView(calculation: calc)
                            }
                            .listRowBackground(AppTheme.cardBackground)
                            .listRowSeparatorTint(AppTheme.separator)
                        }
                        .onDelete(perform: deleteCalculations)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !calculations.isEmpty {
                        Button("Clear") {
                            isShowingClearAlert = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationDestination(item: $selectedCalculation) { calc in
                ReportView(vm: ReportViewModel(result: calc.optimizationResult))
                    .environmentObject(inputVM)
            }
            .alert("Clear history?", isPresented: $isShowingClearAlert) {
                Button("Clear All", role: .destructive) {
                    clearAllHistory()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
            Text("No calculations yet")
                .font(AppTheme.titleFont(size: 18))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Your optimization results will appear here")
                .font(AppTheme.bodyFont(size: 14))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteCalculations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(calculations[index])
        }
        try? modelContext.save()
    }

    private func clearAllHistory() {
        for calculation in calculations {
            modelContext.delete(calculation)
        }
        try? modelContext.save()
    }
}

struct CalculationRowView: View {
    let calculation: SavedCalculation

    private var balanceFormatted: String {
        formatCents(calculation.balanceInCents)
    }

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: calculation.createdAt)
    }

    private var matchBadge: String {
        switch calculation.matchQualityKind {
        case "perfect": return "Perfect"
        case "partial": return "Partial"
        default: return "No solution"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(balanceFormatted)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(dateFormatted)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Text(matchBadge)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(calculation.matchQualityKind == "perfect" ? AppTheme.accentGreen : AppTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    calculation.matchQualityKind == "perfect" ? AppTheme.accentGreenLight : Color.gray.opacity(0.15),
                    in: Capsule()
                )
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
        }
        .padding(.vertical, 4)
    }

    private func formatCents(_ cents: Int) -> String {
        let decimal = Decimal(cents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: decimal as NSDecimalNumber) ?? "$0.00"
    }
}

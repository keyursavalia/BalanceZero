import SwiftUI

struct ReportView: View {
    @EnvironmentObject private var inputVM: InputViewModel
    @ObservedObject var vm: ReportViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    ReportHeaderView(vm: vm)

                    statCards

                    bestCombinationSection

                    summaryBanner

                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            startOverBar
        }
        .navigationTitle("Optimization Report")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Share sheet — placeholder for MVP
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: 12) {
            StatCardView(label: "Original Balance", value: vm.originalBalanceForDisplay)
            StatCardView(label: "Total Spent", value: vm.totalSpentForDisplay)
        }
    }

    // MARK: - Best Combination

    private var bestCombinationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Best Combination")
                    .font(AppTheme.titleFont())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                if vm.isPerfectMatch {
                    Text(vm.matchLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.accentGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentGreenLight, in: Capsule())
                }
            }

            if vm.hasMultipleCombinations {
                HStack(spacing: 16) {
                    Button {
                        if vm.selectedComboIndex > 0 {
                            vm.selectedComboIndex -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(vm.selectedComboIndex > 0 ? AppTheme.accent : AppTheme.textSecondary.opacity(0.4))
                            .padding(8)
                    }
                    .disabled(vm.selectedComboIndex == 0)

                    Text(vm.combinationSelectorTitle)
                        .font(AppTheme.bodyFont(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)

                    Button {
                        if vm.selectedComboIndex < vm.result.allSelections.count - 1 {
                            vm.selectedComboIndex += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(vm.selectedComboIndex < vm.result.allSelections.count - 1 ? AppTheme.accent : AppTheme.textSecondary.opacity(0.4))
                            .padding(8)
                    }
                    .disabled(vm.selectedComboIndex >= vm.result.allSelections.count - 1)
                }
            }

            if vm.currentItems.isEmpty {
                Text("No items could be selected within your balance.")
                    .font(AppTheme.bodyFont(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(vm.currentItems, id: \.item.id) { selected in
                    ResultItemRowView(selected: selected)
                }
            }
        }
    }

    // MARK: - Summary Banner

    private var summaryBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppTheme.accent)
                .font(.system(size: 18))

            Text(attributedSummary)
                .font(AppTheme.bodyFont(size: 14))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private var attributedSummary: AttributedString {
        var base = AttributedString(vm.summaryMessage)
        // Bold and color the dollar amount in the summary
        if let range = base.range(of: "$0.00") {
            base[range].foregroundColor = AppTheme.accent
            base[range].font = .system(size: 14, weight: .semibold)
        }
        return base
    }

    // MARK: - Start Over Bar

    private var startOverBar: some View {
        Button {
            inputVM.reset()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Text("Start Over")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.clockwise")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .background(.ultraThinMaterial)
    }
}

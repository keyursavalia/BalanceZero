import SwiftUI

struct ReportView: View {
    @EnvironmentObject private var inputVM: InputViewModel
    @ObservedObject var vm: ReportViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    ReportHeaderView(vm: vm)
                        .padding(.top, 8)

                    statGrid

                    combinationSection

                    infoCard

                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: sizeClass == .regular ? 680 : .infinity)
                .frame(maxWidth: .infinity)
            }

            startOverBar
        }
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Share — placeholder for post-MVP
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.primaryFixed, in: Circle())
                }
            }
        }
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        HStack(spacing: 12) {
            StatCardView(label: "Original Balance", value: vm.originalBalanceForDisplay)
            StatCardView(label: "Total Spent", value: vm.totalSpentForDisplay)
        }
    }

    // MARK: - Best Combination Section

    private var combinationSection: some View {
        VStack(spacing: 14) {
            // Section header + match badge + navigator
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best Combination")
                        .font(AppTheme.headlineFont(size: 20))
                        .foregroundStyle(AppTheme.onSurface)

                    // Match quality badge
                    matchQualityBadge
                }

                Spacer()

                // Combination navigator (shown only when multiple combos exist)
                if vm.hasMultipleCombinations {
                    comboNavigator
                }
            }

            // Items list or empty state
            if vm.currentItems.isEmpty {
                emptyItemsCard
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.currentItems, id: \.item.id) { selected in
                        ResultItemRowView(selected: selected)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var matchQualityBadge: some View {
        switch vm.result.matchQuality {
        case .perfect:
            Text("Perfect Match")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(AppTheme.successGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.successGreenBg, in: Capsule())

        case .partial:
            Text("Best Possible")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(AppTheme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.primaryFixed, in: Capsule())

        case .noSolution:
            Text("No Solution")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(AppTheme.outline)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.surfaceHigh, in: Capsule())
        }
    }

    private var comboNavigator: some View {
        HStack(spacing: 0) {
            Button {
                if vm.selectedComboIndex > 0 {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        vm.selectedComboIndex -= 1
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(vm.selectedComboIndex > 0 ? AppTheme.primary : AppTheme.outlineVariant)
                    .frame(width: 32, height: 32)
            }
            .disabled(vm.selectedComboIndex == 0)

            Text(vm.combinationSelectorTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .frame(minWidth: 80, alignment: .center)

            Button {
                if vm.selectedComboIndex < vm.result.allSelections.count - 1 {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        vm.selectedComboIndex += 1
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(vm.selectedComboIndex < vm.result.allSelections.count - 1 ? AppTheme.primary : AppTheme.outlineVariant)
                    .frame(width: 32, height: 32)
            }
            .disabled(vm.selectedComboIndex >= vm.result.allSelections.count - 1)
        }
        .background(AppTheme.surfaceContainer, in: Capsule())
    }

    private var emptyItemsCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryFixed.opacity(0.4))
                    .frame(width: 72, height: 72)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.primary)
            }
            Text("No items could be selected within your balance.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - Info / Summary Card

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.primary)

            Text(vm.summaryMessage)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(AppTheme.primaryFixed.opacity(0.45), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }

    // MARK: - Start Over Bar

    private var startOverBar: some View {
        Button {
            inputVM.reset()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .bold))
                Text("Start Over")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL, style: .continuous)
            )
            .shadow(color: AppTheme.primary.opacity(0.22), radius: 16, x: 0, y: 6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }
}

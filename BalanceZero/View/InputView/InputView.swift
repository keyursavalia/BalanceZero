import SwiftUI

struct InputView: View {
    @EnvironmentObject private var vm: InputViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    BalanceInputCard(
                        balanceText: $vm.balanceText,
                        balanceInCents: vm.balanceInCents
                    )

                    itemsSection

                    // Spacer so content clears the pinned bottom bar
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            bottomBar
        }
        .navigationTitle("BalanceZero")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Settings button (to be developed)
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .navigationDestination(item: $vm.result) { result in
            ReportView(vm: ReportViewModel(result: result))
                .environmentObject(vm)
        }
        .alert("Check Your Input", isPresented: $vm.showValidationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.validationMessage)
        }
    }

    // Items Section

    private var itemsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Items to Buy")
                    .font(AppTheme.titleFont())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(vm.itemCountLabel)
                    .font(AppTheme.bodyFont(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            ForEach($vm.items) { $item in
                ItemRowView(item: $item)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            AddItemButton {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    vm.addItem()
                }
            }
        }
    }

    // Bottom Bar (total + calculate)

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Total")
                        .font(AppTheme.bodyFont(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(vm.currentTotalForDisplay, format: .currency(code: "USD"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Spacer()

                Button {
                    vm.calculate()
                } label: {
                    HStack(spacing: 8) {
                        if vm.isCalculating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Calculate Zero")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        vm.canCalculate ? AppTheme.accent : AppTheme.accent.opacity(0.4),
                        in: Capsule()
                    )
                }
                .disabled(!vm.canCalculate || vm.isCalculating)
                .animation(.easeInOut(duration: 0.2), value: vm.canCalculate)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }
}

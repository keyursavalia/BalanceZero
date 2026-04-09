import SwiftUI

struct ReportHeaderView: View {
    let vm: ReportViewModel

    private var isPerfect: Bool { vm.isPerfectMatch }
    private var isZero: Bool { vm.remainingBalanceForDisplay == "$0.00" }

    var body: some View {
        VStack(spacing: 10) {
            Text("REMAINING BALANCE")
                .font(.system(size: 10, weight: .bold))
                .tracking(2.5)
                .foregroundStyle(AppTheme.onSurfaceVariant)

            Text(vm.remainingBalanceForDisplay)
                .font(.system(size: 58, weight: .heavy))
                .foregroundStyle(isZero ? AppTheme.successGreen : AppTheme.primary)
                .contentTransition(.numericText())

            if isPerfect {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Balance Zero Achieved")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(AppTheme.successGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppTheme.successGreenBg, in: Capsule())
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isPerfect)
    }
}

import SwiftUI

struct ReportHeaderView: View {
    let vm: ReportViewModel

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGreenLight)
                    .frame(width: 100, height: 100)

                Image(systemName: vm.isPerfectMatch ? "checkmark" : "chart.bar.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AppTheme.accentGreen)
            }

            VStack(spacing: 6) {
                Text("REMAINING BALANCE")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(vm.remainingBalanceForDisplay)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accentGreen)
            }
        }
        .padding(.top, 8)
    }
}

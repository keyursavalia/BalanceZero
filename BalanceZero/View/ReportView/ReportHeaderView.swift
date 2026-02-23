import SwiftUI

struct ReportHeaderView: View {
    let vm: ReportViewModel

    var body: some View {
        VStack(spacing: 6) {
            Text("REMAINING BALANCE")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            Text(vm.remainingBalanceForDisplay)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.accentGreen)
        }
        .padding(.top, 8)
    }
}

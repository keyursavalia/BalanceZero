import SwiftUI

struct StatCardView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.outline)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.onSurface)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceLowest, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: AppTheme.onSurface.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

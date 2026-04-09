import SwiftUI

struct AddItemButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 17, weight: .medium))
                Text("Add another item")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(AppTheme.outline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(
                        AppTheme.outlineVariant,
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

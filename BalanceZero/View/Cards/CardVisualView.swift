import SwiftUI

/// Reusable credit-card-shaped view. Used in the carousel, card detail header, and design picker.
struct CardVisualView: View {
    let name: String
    let balanceInCents: Int
    let design: CardDesign

    /// When true the card renders at a smaller size suitable for design picker pills.
    var isCompact: Bool = false

    /// For `.custom` design: hex color string (e.g. "7b2ff7"). If empty, falls back to design defaults.
    var customColorHex: String = ""
    /// For `.custom` design: company/brand name shown as type badge. If empty, no badge shown.
    var customCompanyName: String = ""

    private var effectiveGradientColors: [Color] {
        if design == .custom, !customColorHex.isEmpty {
            let base = Color(hex: customColorHex)
            return [base.opacity(0.85), base]
        }
        return design.gradientColors
    }

    private var effectiveTypeLabel: String {
        if design == .custom {
            return customCompanyName.uppercased()
        }
        return design.typeLabel
    }

    private var effectiveAccentColor: Color {
        if design == .custom, !customColorHex.isEmpty {
            return Color(hex: customColorHex).opacity(0.5)
        }
        return design.accentColor
    }

    private var balance: String {
        formatCents(balanceInCents)
    }

    private var isOverdrawn: Bool { balanceInCents < 0 }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: effectiveGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative blobs — give the card depth and texture
            decorativeOverlay

            // Card content
            VStack(alignment: .leading, spacing: 0) {
                topRow
                Spacer()
                bottomBlock
            }
            .padding(isCompact ? 14 : 26)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: isCompact ? 12 : AppTheme.cornerRadiusLG,
                style: .continuous
            )
        )
        .aspectRatio(1.586, contentMode: .fit)
        .shadow(
            color: effectiveGradientColors.first?.opacity(isCompact ? 0 : 0.35) ?? .clear,
            radius: 24,
            x: 0,
            y: 10
        )
    }

    // MARK: - Top row: chip + type badge

    private var topRow: some View {
        HStack(alignment: .top) {
            chipView
            Spacer()
            typeBadge
        }
    }

    // EMV chip — gold rounded rect with a simple grid texture
    private var chipView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isCompact ? 2 : 4, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "D4AF37"), Color(hex: "B8960C")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isCompact ? 22 : 38, height: isCompact ? 16 : 28)

            // Grid lines
            VStack(spacing: isCompact ? 2 : 3) {
                ForEach(0..<3) { _ in
                    HStack(spacing: isCompact ? 2 : 3) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                                .frame(
                                    width: isCompact ? 4 : 7,
                                    height: isCompact ? 3 : 5
                                )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var typeBadge: some View {
        let label = effectiveTypeLabel
        if !label.isEmpty {
            Text(label)
                .font(.system(size: isCompact ? 8 : 14, weight: .black, design: .default))
                .tracking(isCompact ? 0.5 : 1.5)
                .foregroundStyle(Color.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else if design != .custom {
            Image(systemName: design.symbolName)
                .font(.system(size: isCompact ? 10 : 20, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.72))
        }
    }

    // MARK: - Bottom block: balance + name

    private var bottomBlock: some View {
        VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
            Text("AVAILABLE BALANCE")
                .font(.system(size: isCompact ? 6 : 9, weight: .bold))
                .tracking(isCompact ? 0.5 : 1.5)
                .foregroundStyle(Color.white.opacity(0.6))

            Text(balance)
                .font(.system(size: isCompact ? 18 : 34, weight: .heavy))
                .foregroundStyle(isOverdrawn ? Color(hex: "ffcdd2") : Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(name)
                .font(.system(size: isCompact ? 8 : 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.78))
                .lineLimit(1)
        }
    }

    // MARK: - Decorative overlay

    private var decorativeOverlay: some View {
        ZStack {
            // Large glow blob — top right
            Circle()
                .fill(Color.white.opacity(0.09))
                .frame(
                    width: isCompact ? 80 : 180,
                    height: isCompact ? 80 : 180
                )
                .blur(radius: isCompact ? 12 : 28)
                .offset(x: isCompact ? 28 : 80, y: isCompact ? -24 : -60)

            // Small accent blob — bottom left
            Circle()
                .fill(effectiveAccentColor.opacity(0.14))
                .frame(
                    width: isCompact ? 50 : 120,
                    height: isCompact ? 50 : 120
                )
                .blur(radius: isCompact ? 8 : 18)
                .offset(x: isCompact ? -18 : -40, y: isCompact ? 18 : 48)
        }
        .allowsHitTesting(false)
    }

    private func formatCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(
            from: (Decimal(cents) / 100) as NSDecimalNumber
        ) ?? "$0.00"
    }
}

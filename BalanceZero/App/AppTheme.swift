import SwiftUI

enum AppTheme {

    // MARK: - Surface Hierarchy (Stitch "Kinetic Sanctuaries" token system)
    static let background       = Color(hex: "f8f9fc")   // base canvas
    static let surfaceLowest    = Color(hex: "ffffff")   // highest-priority cards
    static let surfaceLow       = Color(hex: "f2f3f6")   // secondary grouping
    static let surfaceContainer = Color(hex: "edeef1")   // neutral container
    static let surfaceHigh      = Color(hex: "e7e8eb")   // recessed inputs
    static let surfaceHighest   = Color(hex: "e1e2e5")   // deepest tonal shift

    // MARK: - Brand (Deep Indigo)
    static let primary          = Color(hex: "002daa")
    static let primaryContainer = Color(hex: "1a44d4")
    static let primaryFixed     = Color(hex: "dde1ff")
    static let primaryFixedDim  = Color(hex: "b9c3ff")

    // MARK: - Text
    static let onSurface        = Color(hex: "191c1e")
    static let onSurfaceVariant = Color(hex: "444655")
    static let outline          = Color(hex: "747686")
    static let outlineVariant   = Color(hex: "c4c5d7")

    // MARK: - Warm Accent — used for "Perfect Match" state
    static let tertiaryFixed    = Color(hex: "ffdbd1")
    static let tertiary         = Color(hex: "771e00")

    // MARK: - Success — used for $0.00 remaining balance
    static let successGreen     = Color(hex: "1b5e20")
    static let successGreenBg   = Color(hex: "e8f5e9")

    // MARK: - Legacy Aliases (keeps unchanged code compiling)
    static let cardBackground   = surfaceLowest
    static let accent           = primary
    static let accentGreen      = successGreen
    static let accentGreenLight = successGreenBg
    static let textPrimary      = onSurface
    static let textSecondary    = onSurfaceVariant
    static let separator        = outlineVariant

    // MARK: - Corner Radii
    static let cornerRadius: CGFloat    = 16   // default cards
    static let cornerRadiusMD: CGFloat  = 20   // medium cards
    static let cornerRadiusLG: CGFloat  = 24   // large cards / balance card
    static let cornerRadiusXL: CGFloat  = 32   // CTA buttons / tab bar
    static let innerCornerRadius: CGFloat = 12

    // MARK: - Gradient
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryContainer],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Typography (system fonts tuned to match design weight/tracking targets)
    static func displayFont(size: CGFloat = 52) -> Font {
        .system(size: size, weight: .heavy, design: .default)
    }
    static func headlineFont(size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    static func titleFont(size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    static func bodyFont(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    static func labelFont(size: CGFloat = 11) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    static func balanceFont(size: CGFloat = 52) -> Font {
        .system(size: size, weight: .heavy, design: .default)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

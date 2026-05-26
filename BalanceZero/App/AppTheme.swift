import SwiftUI

enum AppTheme {

    // MARK: - Adaptive Color Helper

    private static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }

    // MARK: - Surface Hierarchy

    static let background       = adaptive(light: "f8f9fc", dark: "0f1012")
    static let surfaceLowest    = adaptive(light: "ffffff", dark: "1c1c22")
    static let surfaceLow       = adaptive(light: "f2f3f6", dark: "191920")
    static let surfaceContainer = adaptive(light: "edeef1", dark: "21212a")
    static let surfaceHigh      = adaptive(light: "e7e8eb", dark: "28272f")
    static let surfaceHighest   = adaptive(light: "e1e2e5", dark: "2e2d36")

    // MARK: - Brand (Deep Indigo)

    static let primary          = adaptive(light: "002daa", dark: "8fa8ff")
    static let primaryContainer = adaptive(light: "1a44d4", dark: "4d6fff")
    static let primaryFixed     = adaptive(light: "dde1ff", dark: "1e2857")
    static let primaryFixedDim  = adaptive(light: "b9c3ff", dark: "263368")

    // MARK: - Text

    static let onSurface        = adaptive(light: "191c1e", dark: "e2e3e9")
    static let onSurfaceVariant = adaptive(light: "444655", dark: "c3c4d2")
    static let outline          = adaptive(light: "747686", dark: "8f90a2")
    static let outlineVariant   = adaptive(light: "c4c5d7", dark: "3a3b4e")

    // MARK: - Warm Accent — used for "Perfect Match" state

    static let tertiaryFixed    = adaptive(light: "ffdbd1", dark: "4a1000")
    static let tertiary         = adaptive(light: "771e00", dark: "ffb59e")

    // MARK: - Success — used for $0.00 remaining balance

    static let successGreen     = adaptive(light: "1b5e20", dark: "6fbf73")
    static let successGreenBg   = adaptive(light: "e8f5e9", dark: "0a2410")

    // MARK: - Legacy Aliases (keeps unchanged code compiling)

    static let cardBackground   = surfaceLowest
    static let accent           = primary
    static let accentGreen      = successGreen
    static let accentGreenLight = successGreenBg
    static let textPrimary      = onSurface
    static let textSecondary    = onSurfaceVariant
    static let separator        = outlineVariant

    // MARK: - Corner Radii

    static let cornerRadius: CGFloat     = 16
    static let cornerRadiusMD: CGFloat   = 20
    static let cornerRadiusLG: CGFloat   = 24
    static let cornerRadiusXL: CGFloat   = 32
    static let innerCornerRadius: CGFloat = 12

    // MARK: - Gradient

    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [primary, primaryContainer], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - Typography

    static func displayFont(size: CGFloat = 52) -> Font { .system(size: size, weight: .heavy) }
    static func headlineFont(size: CGFloat = 24) -> Font { .system(size: size, weight: .bold) }
    static func titleFont(size: CGFloat = 20) -> Font    { .system(size: size, weight: .bold) }
    static func bodyFont(size: CGFloat = 15) -> Font     { .system(size: size, weight: .regular) }
    static func labelFont(size: CGFloat = 11) -> Font    { .system(size: size, weight: .bold) }
    static func balanceFont(size: CGFloat = 52) -> Font  { .system(size: size, weight: .heavy) }
}

// MARK: - Color + UIColor hex initializers

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   CGFloat((int >> 16) & 0xFF) / 255,
            green: CGFloat((int >> 8)  & 0xFF) / 255,
            blue:  CGFloat(int         & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue:  Double(int         & 0xFF) / 255
        )
    }
}

// MARK: - Keyboard dismiss

extension View {
    /// Dismisses the keyboard when the user taps on background empty space.
    func dismissKeyboardOnBackgroundTap() -> some View {
        background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
        )
    }
}

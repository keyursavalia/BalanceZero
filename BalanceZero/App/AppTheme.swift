import SwiftUI

enum AppTheme {
    // Colors
    static let background       = Color(hex: "EEF0F8")
    static let cardBackground   = Color.white
    static let accent           = Color(hex: "1A1FC8")
    static let accentGreen      = Color(hex: "2E7D52")
    static let accentGreenLight = Color(hex: "D6EBE0")
    static let textPrimary      = Color(hex: "111111")
    static let textSecondary    = Color(hex: "8A8A9A")
    static let separator        = Color(hex: "E0E0EA")

    // Typography helpers
    static func balanceFont(size: CGFloat = 52) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func titleFont(size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func bodyFont(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    // Radius
    static let cornerRadius: CGFloat        = 16
    static let innerCornerRadius: CGFloat   = 12

    // Card shadow
    static var cardShadow: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
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

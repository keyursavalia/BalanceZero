import SwiftUI

enum CardDesign: String, CaseIterable, Codable {
    case classic
    case midnight
    case visa
    case mastercard
    case target
    case starbucks
    case silver
    case custom

    var displayName: String {
        switch self {
        case .classic:    return "Classic"
        case .midnight:   return "Midnight"
        case .visa:       return "Visa"
        case .mastercard: return "Mastercard"
        case .target:     return "Target"
        case .starbucks:  return "Starbucks"
        case .silver:     return "Silver"
        case .custom:     return "Custom"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .classic:    return [Color(hex: "002daa"), Color(hex: "1a44d4")]
        case .midnight:   return [Color(hex: "0d1117"), Color(hex: "21262d")]
        case .visa:       return [Color(hex: "1a237e"), Color(hex: "1976d2")]
        case .mastercard: return [Color(hex: "b71c1c"), Color(hex: "e65100")]
        case .target:     return [Color(hex: "b71c1c"), Color(hex: "e53935")]
        case .starbucks:  return [Color(hex: "1b5e20"), Color(hex: "2e7d32")]
        case .silver:     return [Color(hex: "546e7a"), Color(hex: "90a4ae")]
        case .custom:     return [Color(hex: "4a148c"), Color(hex: "7b1fa2")]
        }
    }

    var symbolName: String {
        switch self {
        case .classic:    return "creditcard.fill"
        case .midnight:   return "moon.fill"
        case .visa:       return "v.square.fill"
        case .mastercard: return "circle.lefthalf.filled"
        case .target:     return "target"
        case .starbucks:  return "star.fill"
        case .silver:     return "circle.fill"
        case .custom:     return "paintpalette.fill"
        }
    }

    var typeLabel: String {
        switch self {
        case .visa:       return "VISA"
        case .mastercard: return "MC"
        case .target:     return "TARGET"
        case .starbucks:  return "SBUX"
        default:          return ""
        }
    }

    var accentColor: Color {
        switch self {
        case .classic:    return Color(hex: "b9c3ff")
        case .midnight:   return Color(hex: "8b949e")
        case .visa:       return Color(hex: "90caf9")
        case .mastercard: return Color(hex: "ffccbc")
        case .target:     return Color(hex: "ef9a9a")
        case .starbucks:  return Color(hex: "a5d6a7")
        case .silver:     return Color(hex: "cfd8dc")
        case .custom:     return Color(hex: "ce93d8")
        }
    }
}

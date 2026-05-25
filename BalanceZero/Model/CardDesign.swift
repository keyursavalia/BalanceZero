import SwiftUI

enum CardDesign: String, CaseIterable, Codable {
    case classic
    case midnight
    case visa
    case mastercard
    case target
    case starbucks
    case amex
    case rose

    var displayName: String {
        switch self {
        case .classic:    return "Classic"
        case .midnight:   return "Midnight"
        case .visa:       return "Visa"
        case .mastercard: return "Mastercard"
        case .target:     return "Target"
        case .starbucks:  return "Starbucks"
        case .amex:       return "Amex"
        case .rose:       return "Rose"
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
        case .amex:       return [Color(hex: "263238"), Color(hex: "37474f")]
        case .rose:       return [Color(hex: "880e4f"), Color(hex: "c2185b")]
        }
    }

    // Used in the design picker pill and as decorative element on the card
    var symbolName: String {
        switch self {
        case .classic:    return "creditcard.fill"
        case .midnight:   return "moon.fill"
        case .visa:       return "v.square.fill"
        case .mastercard: return "circle.lefthalf.filled"
        case .target:     return "target"
        case .starbucks:  return "star.fill"
        case .amex:       return "shield.fill"
        case .rose:       return "heart.fill"
        }
    }

    // Short badge displayed in the top-right of the card; empty for non-branded designs
    var typeLabel: String {
        switch self {
        case .visa:       return "VISA"
        case .mastercard: return "MC"
        case .target:     return "TARGET"
        case .starbucks:  return "SBUX"
        case .amex:       return "AMEX"
        default:          return ""
        }
    }

    // Lighter highlight color used for decorative blobs on the card surface
    var accentColor: Color {
        switch self {
        case .classic:    return Color(hex: "b9c3ff")
        case .midnight:   return Color(hex: "8b949e")
        case .visa:       return Color(hex: "90caf9")
        case .mastercard: return Color(hex: "ffccbc")
        case .target:     return Color(hex: "ef9a9a")
        case .starbucks:  return Color(hex: "a5d6a7")
        case .amex:       return Color(hex: "b0bec5")
        case .rose:       return Color(hex: "f48fb1")
        }
    }
}

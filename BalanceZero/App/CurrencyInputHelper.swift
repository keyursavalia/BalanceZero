import Foundation

/// Shared logic for modern currency input: digits only, fixed period, max 5 digits (2 decimals).
enum CurrencyInputHelper {

    static func extractDigits(from s: String) -> String {
        String(s.filter { $0.isNumber }.prefix(5))
    }

    static func formatDigitsToAmount(_ digits: String) -> String {
        if digits.isEmpty { return "0.00" }
        let padded = String(repeating: "0", count: max(0, 3 - digits.count)) + digits
        let centsPart = String(padded.suffix(2))
        let dollarsPart = String(padded.dropLast(2))
        let trimmedDollars = dollarsPart.drop(while: { $0 == "0" })
        return "\(trimmedDollars.isEmpty ? "0" : String(trimmedDollars)).\(centsPart)"
    }

    static func centsFromFormatted(_ formatted: String) -> Int {
        guard let value = Decimal(string: formatted) else { return 0 }
        return max(0, NSDecimalNumber(decimal: value * 100).intValue)
    }

    static func formattedFromCents(_ cents: Int) -> String {
        if cents == 0 { return "0.00" }
        let digits = String(cents)
        let padded = String(repeating: "0", count: max(0, 3 - digits.count)) + digits
        let centsPart = String(padded.suffix(2))
        let dollarsPart = String(padded.dropLast(2))
        let trimmedDollars = dollarsPart.drop(while: { $0 == "0" })
        return "\(trimmedDollars.isEmpty ? "0" : String(trimmedDollars)).\(centsPart)"
    }
}

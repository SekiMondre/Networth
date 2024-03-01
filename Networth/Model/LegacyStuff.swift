//

import SwiftUI

extension Identifiable where Self: Hashable {
    var id: Int { hashValue }
}

class PriceFormatter {
    
    static func format(_ number: Double) -> String {
        formatter.string(from: NSNumber(value: number)) ?? "error"
    }
    
    static func format(_ number: Double, toCurrency: Currency) -> String {
        if toCurrency == .btc {
            return String(format: "%.8f", number)
        }
        formatter.locale = Locale(identifier: toCurrency.locale)
        return formatter.string(from: NSNumber(value: number)) ?? "error"
    }
    
    static var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt-BR")
        return formatter
    }()
}

extension Color {
    static func random() -> Color {
        Color(.displayP3, red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1), opacity: 1)
    }
}

func getColor(for symbol: String) -> Color {
    switch symbol {
    case "BTC": return .orange
    case "ETH": return .gray
    case "ADA": return .blue
    case "SOL": return .green
    case "DOT": return .pink
    case "AVAX": return .red
    case "ATOM": return .purple
    case "BNB": return .yellow
    case "CAKE": return .orange
    default: return Color.random()
    }
    }

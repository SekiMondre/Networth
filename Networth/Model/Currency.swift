import SwiftUI

enum Currency: CaseIterable, Identifiable {
    var id: Self { self }
    
    case usd
    case brl
    case btc
    
    var name: String {
        switch self {
        case .brl: return "Real"
        case .usd: return "US Dollar"
        case .btc: return "Bitcoin"
        }
    }
    
    var symbol: String {
        switch self {
        case .brl: return "BRL"
        case .usd: return "USD"
        case .btc: return "BTC"
        }
    }
    
    var ticker: String {
        symbol
    }
    
    var locale: String {
        switch self {
        case .brl: return "pt-BR"
        case .usd: return "en-US"
        default: return ""
        }
    }
}

//

import Foundation
import SwiftUI

struct LatestQuotes {
    let quotes: [String: Quote]
}

struct Quote {
    let name: String
    let symbol: String
    let price: Double
}

protocol Asset {
    var ticker: String { get }
    var name: String { get }
    var price: Price { get }
    var color: Color { get } // ?
}

protocol QuantifiableAsset: Asset {
    var quantity: Double { get }
    var unitaryPrice: Price { get }
}

extension QuantifiableAsset {
    var price: Price {
        quantity * unitaryPrice
    }
}

//struct AnyAsset: Asset {
//    let ticker: String
//    let name: String
//    let price: Price
//    let color: Color // ?
//}

struct Cryptocurrency: QuantifiableAsset {
    let ticker: String
    let name: String
    let network: String
    let category: String
    let quantity: Double// Decimal
    let unitaryPrice: Price
    let color: Color
}

enum AssetClass {
    case fixedIncome
    case equities // stocks
    case funds
    case crypto
}
extension AssetClass {
    var color: Color {
        switch self {
        case .fixedIncome: return .cyan
        case .equities: return .orange
        case .funds: return .indigo
        case .crypto: return .red
        }
    }
    var title: String {
        switch self {
        case .fixedIncome: return "Fixed Income"
        case .equities: return "Stocks & Equities"
        case .funds: return "Funds"
        case .crypto: return "Crypto"
        }
    }
}

struct Portfolio {
    let assetAllocation: [AssetClass: [Asset]]
}

extension Portfolio {
    struct AnyAsset: Asset {
        let ticker: String
        let name: String
        let price: Price
        let color: Color // ?
    }
    
    struct Cryptocurrency: QuantifiableAsset {
        let ticker: String
        let name: String
        let network: String
        let category: String
        let quantity: Double// Decimal
        let unitaryPrice: Price
        let color: Color
    }
    
    struct Stock: QuantifiableAsset {
        let ticker: String
        let name: String
        let quantity: Double// Decimal
        let unitaryPrice: Price
        let color: Color
    }
}

extension Portfolio.AnyAsset {
    static func stubFixedIncome() -> [Portfolio.AnyAsset] {
        [
            Portfolio.AnyAsset(
                ticker: "CDI",
                name: "CDB Pós-fixado",
                price: Price.brl(39785.78),
                color: .blue)
//            Portfolio.AnyAsset(
//                ticker: "IPCA+",
//                name: "CDB Inflação",
//                price: Price.brl(5600),
//                color: .indigo),
        ]
    }
    static func stubFunds() -> [Portfolio.AnyAsset] {
        [
            Portfolio.AnyAsset(
                ticker: "FUND",
                name: "All Funds",
                price: Price.brl(1606.74),
                color: .purple),
            Portfolio.AnyAsset(
                ticker: "TI",
                name: "Tech Invest",
                price: Price.brl(4437.42),
                color: .yellow)
        ]
    }
}
extension Portfolio.Stock {
    static func stubList() -> [Portfolio.Stock] {
        [
            Portfolio.Stock(
                ticker: "AAPL",
                name: "Apple",
                quantity: 20,
                unitaryPrice: Price.brl(83.97),
                color: .white),
            Portfolio.Stock(
                ticker: "TSLA",
                name: "Tesla",
                quantity: 5,
                unitaryPrice: Price.brl(143.69),
                color: .red),
            Portfolio.Stock(
                ticker: "BR",
                name: "Brasileiras",
                quantity: 1,
                unitaryPrice: Price.brl(1331.50),
                color: .green)
        ]
    }
}

final class PortfolioService {
    
    private let api = CoinMarketCapAPI()
    
    func consolidatePortfolio() async throws -> Portfolio {
        return Portfolio(assetAllocation: [
            .crypto : try await consolidateCryptoAssets(),
            .fixedIncome: try await consolidateFixedIncomeAssets(),
            .funds: try await consolidateFundsAssets(),
            .equities: try await consolidateEquityAssets()
        ])
    }
    
    func consolidateCryptoAssets() async throws -> [Asset] {
        let rawData = try! DataLoader.load([String:[Double]].self, fromFile: "crypto-assets")
        let coins = rawData.mapValues { $0.reduce(0, +) }
        let tickers: [String] = Array(coins.keys)
        let latestQuotes = try await fetchLatestQuotes(for: tickers)
        
        return coins.map { (ticker, value) -> Asset in
            let quote = latestQuotes.quotes[ticker]!
            let asset = Portfolio.Cryptocurrency(
                ticker: ticker,
                name: quote.name,
                network: "",
                category: "",
                quantity: value,
                unitaryPrice: Price.usd(quote.price),
                color: getColor(for: ticker))
            return asset
        }
    }
    
    func consolidateEquityAssets() async throws -> [Asset] {
        Portfolio.Stock.stubList()
    }
    
    func consolidateFixedIncomeAssets() async throws -> [Asset] {
        Portfolio.AnyAsset.stubFixedIncome()
    }
    
    func consolidateFundsAssets() async throws -> [Asset] {
        Portfolio.AnyAsset.stubFunds()
    }
    
    func fetchLatestQuotes(for tickers: [String]) async throws -> LatestQuotes {
//        print("getting prices...")
        let quotes: [String: [CoinMarketCapAPI.Cryptocurrency]]
        if try Config.get().useMock {
            typealias QuotesSchema = CoinMarketCapAPI.Schema<[String:[CoinMarketCapAPI.Cryptocurrency]]>
            quotes = try DataLoader.load(QuotesSchema.self, fromFile: "quotes-latest-mock").data
        } else {
            quotes = try await api.getLatestQuotes(for: tickers)
        }
        let latestQuotes = LatestQuotes(quotes: quotes.mapValues {
            guard let coin = $0.first else {
                fatalError() // throw
            }
//            guard let price = coin.quote["USD"]?.price else {
//                fatalError() // throw
//            }
//            return Quote(name: coin.name, symbol: coin.symbol, price: price)
            return Quote(name: coin.name, symbol: coin.symbol, price: coin.quote["USD"]?.price ?? 0.0)
        })
        DispatchQueue.main.sync {
            Exchange.shared.addRate(for: .btc, fromValue: latestQuotes.quotes["BTC"]!.price)
        }
        return latestQuotes
    }
}


//final class PortfolioService {
//    
//    private let api = CoinMarketCapAPI()
//    
////    func consolidatePortfolio() async throws -> Portfolio {
////        return Portfolio(assetAllocation: [
////            .crypto : try await consolidateCryptoAssets(),
////            .fixedIncome: try await consolidateFixedIncomeAssets(),
////            .funds: try await consolidateFundsAssets(),
////            .equities: try await consolidateEquityAssets()
////        ])
////    }
//    
//    func consolidateCryptoAssets() async throws -> [Asset] {
//        let rawData = try! DataLoader.load([String:[Double]].self, fromFile: "crypto-assets")
//        let coins = rawData.mapValues { $0.reduce(0, +) }
//        let tickers: [String] = Array(coins.keys)
//        let latestQuotes = try await fetchLatestQuotes(for: tickers)
//        
//        return coins.map { (ticker, value) -> Asset in
//            let quote = latestQuotes.quotes[ticker]!
//            let asset = Cryptocurrency(
//                ticker: ticker,
//                name: quote.name,
//                network: "",
//                category: "",
//                quantity: value,
//                unitaryPrice: Price.usd(quote.price)
////                color: getColor(for: ticker)
//            )
//            return asset
//        }
//    }
//    
//    func fetchLatestQuotes(for tickers: [String]) async throws -> LatestQuotes {
////        print("getting prices...")
//        let quotes: [String: [CoinMarketCapAPI.Cryptocurrency]]
//        if try Config.get().useMock {
//            typealias QuotesSchema = CoinMarketCapAPI.Schema<[String:[CoinMarketCapAPI.Cryptocurrency]]>
//            quotes = try DataLoader.load(QuotesSchema.self, fromFile: "quotes-latest").data
//        } else {
//            quotes = try await api.getLatestQuotes(for: tickers)
//        }
//        let latestQuotes = LatestQuotes(quotes: quotes.mapValues {
//            guard let coin = $0.first else {
//                fatalError() // throw
//            }
//            guard let price = coin.quote["USD"]?.price else {
//                fatalError() // throw
//            }
//            return Quote(name: coin.name, symbol: coin.symbol, price: price)
//        })
//        DispatchQueue.main.sync {
//            Exchange.shared.addRate(for: .btc, fromValue: latestQuotes.quotes["BTC"]!.price)
//        }
//        return latestQuotes
//    }
//}


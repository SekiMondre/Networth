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
//    var color: Color { get } // ?
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
//    let color: Color
}

final class PortfolioService {
    
    private let api = CoinMarketCapAPI()
    
//    func consolidatePortfolio() async throws -> Portfolio {
//        return Portfolio(assetAllocation: [
//            .crypto : try await consolidateCryptoAssets(),
//            .fixedIncome: try await consolidateFixedIncomeAssets(),
//            .funds: try await consolidateFundsAssets(),
//            .equities: try await consolidateEquityAssets()
//        ])
//    }
    
    func consolidateCryptoAssets() async throws -> [Asset] {
        let rawData = try! DataLoader.load([String:[Double]].self, fromFile: "crypto-assets")
        let coins = rawData.mapValues { $0.reduce(0, +) }
        let tickers: [String] = Array(coins.keys)
        let latestQuotes = try await fetchLatestQuotes(for: tickers)
        
        return coins.map { (ticker, value) -> Asset in
            let quote = latestQuotes.quotes[ticker]!
            let asset = Cryptocurrency(
                ticker: ticker,
                name: quote.name,
                network: "",
                category: "",
                quantity: value,
                unitaryPrice: Price.usd(quote.price)
//                color: getColor(for: ticker)
            )
            return asset
        }
    }
    
    func fetchLatestQuotes(for tickers: [String]) async throws -> LatestQuotes {
//        print("getting prices...")
        let quotes: [String: [CoinMarketCapAPI.Cryptocurrency]]
        if try Config.get().useMock {
            typealias QuotesSchema = CoinMarketCapAPI.Schema<[String:[CoinMarketCapAPI.Cryptocurrency]]>
            quotes = try DataLoader.load(QuotesSchema.self, fromFile: "quotes-latest").data
        } else {
            quotes = try await api.getLatestQuotes(for: tickers)
        }
        let latestQuotes = LatestQuotes(quotes: quotes.mapValues {
            guard let coin = $0.first else {
                fatalError() // throw
            }
            guard let price = coin.quote["USD"]?.price else {
                fatalError() // throw
            }
            return Quote(name: coin.name, symbol: coin.symbol, price: price)
        })
        DispatchQueue.main.sync {
            Exchange.shared.addRate(for: .btc, fromValue: latestQuotes.quotes["BTC"]!.price)
        }
        return latestQuotes
    }
}

final class Exchange {
    
    enum Error: Swift.Error {
        case exchangeRateNotFound
    }
    
    static let shared = Exchange()
    
    let parityCurrency: Currency
//    var rates: [String: Decimal] = [:]
    var rates: [String: Double] = [:]
    
    private init(parityCurrency: Currency = .usd) {
        self.parityCurrency = parityCurrency
    }
    
    func addRate(for currency: Currency, toValue: Double) {//Decimal) {
        let toIdentifier = "\(parityCurrency.ticker)\(currency.ticker)"
        let fromIdentifier = "\(currency.ticker)\(parityCurrency.ticker)"
        let fromValue = 1 / toValue
        rates[toIdentifier] = toValue
        rates[fromIdentifier] = fromValue
//        print("Added rate for \(currency): \(fromIdentifier)")
    }
    
    func addRate(for currency: Currency, fromValue: Double) {//Decimal) {
        let toIdentifier = "\(parityCurrency.ticker)\(currency.ticker)"
        let fromIdentifier = "\(currency.ticker)\(parityCurrency.ticker)"
        let toValue = 1 / fromValue
        rates[toIdentifier] = toValue
        rates[fromIdentifier] = fromValue
//        print("Added rate for \(currency): \(fromIdentifier)")
    }
    
    func exchange(_ value: Double, fromCurrency: Currency, to toCurrency: Currency) throws -> Double {
        if fromCurrency == parityCurrency || toCurrency == parityCurrency {
            guard let exchangeRate = rates["\(fromCurrency.ticker)\(toCurrency.ticker)"] else {
                throw Error.exchangeRateNotFound
            }
            return value * exchangeRate
        } else {
            guard
                let toParityRate = rates["\(fromCurrency.ticker)\(parityCurrency.ticker)"],
                let toTargetRate = rates["\(parityCurrency.ticker)\(toCurrency.ticker)"]
            else {
                throw Error.exchangeRateNotFound
            }
            return value * toParityRate * toTargetRate
        }
    }
}

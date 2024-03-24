import SwiftUI

struct ImpermanentLossView: View {
    
    @ObservedObject var state = ImpermanentLossTracker()
    
    var body: some View {
        List {
            ForEach(state.liquidityPools) { pool in
                HStack {
                    Text(pool.ticker)
                    Spacer()
                    Text(pool.lossPercentage)
                }
            }
        }
        .refreshable {
            do {
                try await state.consolidate()
            } catch {
                print("Error \(error)")
            }
        }
    }
}

#Preview {
    ImpermanentLossView()
}

struct LiquidityPool: Hashable, Identifiable {
//    let ticker: String = ""
    let tickerA: String
    let tickerB: String
    
    let aQuoteAtDeposit: Double
    let bQuoteAtDeposit: Double
    
    let aQuoteNow: Double
    let bQuoteNow: Double
    
    var ticker: String {
        "\(tickerA)-\(tickerB)"
    }
    
    var lossPercentage: String {
        let loss = calculateImpermanentLoss(
            px0: aQuoteAtDeposit,
            py0: bQuoteAtDeposit,
            px1: aQuoteNow,
            py1: bQuoteNow)
        return String(format: "%.2f", abs(loss * 100)) + "%"
    }
}

@MainActor
class ImpermanentLossTracker: ObservableObject {
    
    @Published var liquidityPools: [LiquidityPool] = []
    
    private let api = CoinMarketCapAPI()
    
    func consolidate() async throws {
        let mockDeposits: [LPDeposit] = [
            .init( // volatile pool
                tokenX: .init(ticker: "BTC", price: 51_661.97),
                tokenY: .init(ticker: "AVAX", price: 39.76)
            ),
            .init( // stable pool
                tokenX: .init(ticker: "AERO", price: 0.8535),
                tokenY: .init(ticker: "USDC", price: 1.0008)
            )
        ]
        
        let tickers = Array(Set(mockDeposits
            .map { [$0.tokenX.ticker, $0.tokenY.ticker] }
            .flatMap { $0 }
        ))
        
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
            return Quote(name: coin.name, symbol: coin.symbol, price: coin.quote["USD"]?.price ?? 0.0)
        })
        
        var pools: [LiquidityPool] = []
        for deposit in mockDeposits {
            
            let quoteX = latestQuotes.quotes[deposit.tokenX.ticker]?.price ?? 0
            let quoteY = latestQuotes.quotes[deposit.tokenY.ticker]?.price ?? 0
            
            let lp = LiquidityPool(
                tickerA: deposit.tokenX.ticker,
                tickerB: deposit.tokenY.ticker,
                aQuoteAtDeposit: deposit.tokenX.price,
                bQuoteAtDeposit: deposit.tokenY.price,
                aQuoteNow: quoteX,
                bQuoteNow: quoteY)
            pools.append(lp)
        }
        self.liquidityPools = pools
    }
}

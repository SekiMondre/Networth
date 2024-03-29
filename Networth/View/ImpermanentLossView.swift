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

struct LiquidityPoolItem: Hashable, Identifiable {
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
    
    @Published var liquidityPools: [LiquidityPoolItem] = []
    
    private let api = CoinMarketCapAPI()
    
    func consolidate() async throws {
        let deposits = try DataLoader.load([LPDeposit].self, fromFile: "lp-deposits")
        
        let tickers = Array(Set(deposits
            .map { [$0.tokenA.ticker, $0.tokenB.ticker] }
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
        
        var pools: [LiquidityPoolItem] = []
        for deposit in deposits {
            
            let quoteX = latestQuotes.quotes[deposit.tokenA.ticker]?.price ?? 0
            let quoteY = latestQuotes.quotes[deposit.tokenB.ticker]?.price ?? 0
            
            let lp = LiquidityPoolItem(
                tickerA: deposit.tokenA.ticker,
                tickerB: deposit.tokenB.ticker,
                aQuoteAtDeposit: deposit.tokenA.price,
                bQuoteAtDeposit: deposit.tokenB.price,
                aQuoteNow: quoteX,
                bQuoteNow: quoteY)
            pools.append(lp)
        }
        self.liquidityPools = pools
    }
}

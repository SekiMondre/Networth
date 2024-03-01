//

import Combine
import Foundation
import SwiftUI

enum DisplayType: String {
    case overview = "Portfolio"
    case equities = "Stocks & Equities"
    case crypto = "Cryptocurrency"
}

struct Allocation: Hashable, Identifiable {
    let ticker: String
    let name: String
    let priceValue: String
    let value: Double
    let normalizedValue: Double
    let currency: Currency
    let color: Color
    
//    var price: String {
//        PriceFormatter.format(value, toCurrency: currency)
//    }
}

final class AssetAllocationController: ObservableObject {
    
    @Published var selectedCurrency: Currency = .brl
    @Published var allocations: [Allocation] = []
    var cancellables: Set<AnyCancellable> = []
    
    var balance: String {
        let total = allocations.map { $0.value }.reduce(0,+)
        return PriceFormatter.format(total, toCurrency: selectedCurrency)
    }
    
    private let displayType: DisplayType
    private let service = PortfolioService()
    
    private var portfolio: Portfolio?
    
    init(type: DisplayType) {
        Exchange.shared.addRate(for: .brl, toValue: 4.97)
//        Exchange.shared.addRate(for: .btc, fromValue: 22000)
        
        self.displayType = type
        $selectedCurrency.sink { [weak self] in
            self?.switchCurrency($0)
        }.store(in: &cancellables)
        
        setupPortfolio()
    }
    
    func setupPortfolio() {
        Task {
            do {
                let portfolio = try await service.consolidatePortfolio()
                DispatchQueue.main.async {
                    self.portfolio = portfolio
                    self.switchCurrency(self.selectedCurrency)
                }
            } catch {
                print("Error on portfolio setup: \(error)")
            }
        }
    }
    
    func switchCurrency(_ currency: Currency) {
        guard let portfolio = portfolio else { return }
        switch displayType {
            case .overview:
            displayOverview(portfolio, currency: currency)
            case .equities:
            displayStocks(portfolio, currency: currency)
            case .crypto:
            displayCrypto(portfolio, currency: currency)
        }
    }
    
    func displayOverview(_ portfolio: Portfolio, currency: Currency) {
        let valuesPerClass = try! portfolio.assetAllocation.mapValues { assets in
            try assets.map { try $0.price.value(convertedTo: currency) }.reduce(0, +)
        }
        let totalValue = valuesPerClass.values.reduce(0, +)
        let allocations = valuesPerClass.map { item -> Allocation in
            let normalizedValue = item.value / totalValue
            return Allocation(
                ticker: "",
                name: item.key.title,
                priceValue: PriceFormatter.format(item.value, toCurrency: currency),
                value: item.value,
                normalizedValue: normalizedValue,
                currency: currency,
                color: item.key.color)
        }
        self.allocations = allocations.sorted { $0.value > $1.value }
    }
    
    func displayAssets(_ assets: [Asset], currency: Currency) throws {
        let totalValue = try assets.map { try $0.price.value(convertedTo: currency) }.reduce(0, +)
        let allocations = try assets.map { asset -> Allocation in
            let assetValue = Double(try asset.price.value(convertedTo: currency))
            let normalizedValue = assetValue / totalValue
            return Allocation(
                ticker: asset.ticker,
                name: asset.name,
                priceValue: PriceFormatter.format(assetValue, toCurrency: currency),
                value: assetValue,
                normalizedValue: normalizedValue,
                currency: currency,
                color: asset.color)
        }
        self.allocations = allocations.sorted { $0.value > $1.value }
    }
    
    func displayStocks(_ portfolio: Portfolio, currency: Currency) {
        guard let assets = portfolio.assetAllocation[.equities] else {
            fatalError() // empty state
        }
        try? displayAssets(assets, currency: currency)
    }
    
    func displayCrypto(_ portfolio: Portfolio, currency: Currency) {
        guard let assets = portfolio.assetAllocation[.crypto] else {
            fatalError() // empty state
        }
        try? displayAssets(assets, currency: currency)
    }
}

extension AssetAllocationController {
    var title: String {
        displayType.rawValue
    }
}

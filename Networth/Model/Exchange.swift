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

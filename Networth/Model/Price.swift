struct Price {
    let value: Double//Decimal
    let currency: Currency
}

extension Price {
    
    static func usd(_ v: Double) -> Price {
        Price(value: v, currency: .usd)
    }
    
    static func brl(_ v: Double) -> Price {
        Price(value: v, currency: .brl)
    }
    
    func value(convertedTo anotherCurrency: Currency) throws -> Double {//Decimal {
        if anotherCurrency == self.currency {
            return value
        }
        return try Exchange.shared.exchange(value, fromCurrency: self.currency, to: anotherCurrency)
    }
}

func * (lhs: Price, rhs: Double) -> Price {
    Price(value: lhs.value * rhs, currency: lhs.currency)
}

func * (lhs: Double, rhs: Price) -> Price {
    Price(value: rhs.value * lhs, currency: rhs.currency)
}

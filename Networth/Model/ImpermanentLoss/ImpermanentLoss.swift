import Foundation

// Reference formula: https://www.covalenthq.com/docs/unified-api/guides/how-to-calculate-impermanent-loss-with-examples/

func calculateImpermanentLoss(px0: Double, py0: Double, px1: Double, py1: Double) -> Double {
    let k = px0 * py1 / (px1 * py0) //    let k = (x0 / y0) / (x1 / y1)
    return 2 * sqrt(k) / (1 + k) - 1
}

struct LPDeposit {
//    let timestamp:
    let tokenX: Token
    let tokenY: Token
    
    struct Token {
        let ticker: String
        let price: Double
    }
}

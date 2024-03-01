import Foundation

struct Config {
    let useMock: Bool
    let coinMarketCapApiKey: String
}

extension Config {
    static func get() throws -> Config {
        try DataLoader.load(Config.self, fromFile: "config")
    }
}

extension Config: Codable {
    enum CodingKeys: String, CodingKey {
        case coinMarketCapApiKey = "cmc-api-key"
        case useMock
    }
}

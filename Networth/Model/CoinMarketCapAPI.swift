import Foundation

enum NetworkError: Error {
    case malformedURL
    case noResponse
    case badResponseCode(Int)
}

actor CoinMarketCapAPI {
    
    private let session: URLSession = .shared
    
    private let domain = "pro-api.coinmarketcap.com"
    private let endpoint = "/v2/cryptocurrency/quotes/latest"
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func getLatestQuotes(for tickers: [String]) async throws -> [String:[Cryptocurrency]] {
        guard let url = makeQuotesURL(tickers: tickers) else { throw NetworkError.malformedURL }
        
        let config = try Config.get()
        
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue(config.coinMarketCapApiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        print(url)
        let (_, data) = try await request(urlRequest, type: [String:[Cryptocurrency]].self)
        return data
    }
    
    private func request<T: Decodable>(_ request: URLRequest, type: T.Type) async throws -> (Status, T) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noResponse
        }
        guard isSuccess(httpResponse.statusCode) else {
            throw NetworkError.badResponseCode(httpResponse.statusCode)
        }
        let schema = try decoder.decode(Schema<T>.self, from: data)
        return (schema.status, schema.data)
    }
    
    private func isSuccess(_ statusCode: Int) -> Bool {
        return (200..<300) ~= statusCode
    }
    
    private func makeQuotesURL(tickers: [String]) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = domain
        components.path = endpoint
        components.queryItems = [
            URLQueryItem(name: "symbol", value: tickers.joined(separator: ",")),
            URLQueryItem(name: "convert", value: "USD"),
            URLQueryItem(name: "aux", value: "cmc_rank,platform,max_supply,circulating_supply,total_supply")
        ]
        return components.url
    }
}

extension CoinMarketCapAPI {
    
    // Standard Objects
    struct Schema<T: Decodable>: Decodable {
        let data: T
        let status: Status
    }
    
    struct Status: Decodable {
        /// Current timestamp (ISO 8601) on the server.
        let timestamp: String
        
        /// An internal error code for the current error. If a unique platform error code is not available the HTTP status code is returned. null is returned if there is no error.
        let errorCode: Int?
        
        /// An error message to go along with the error code.
        let errorMessage: String?
        
        /// Number of milliseconds taken to generate this response.
        let elapsed: Int
        
        /// Number of API call credits that were used for this call.
        let creditCount: Int
    }
    
    // API Models
    struct Cryptocurrency: Codable {
        let id: Int
        let name: String
        let symbol: String
        let quote: [String: MarketQuote]
    }
    
    struct MarketQuote: Codable {
        let price: Double
    }
}

import Foundation

final class DataLoader {
    
    private enum Error: Swift.Error {
        case fileDoesNotExist(_ file: String, _ type: String)
    }
    
    static func load<T: Decodable>(_ type: T.Type, fromFile file: String, fileType: String = "json") throws -> T {
        guard let path = Bundle.main.path(forResource: file, ofType: fileType) else {
            throw Error.fileDoesNotExist(file, fileType)
        }
        return try decode(T.self, fromFileAt: path)
    }
    
    private static func decode<T: Decodable>(_ type: T.Type, fromFileAt path: String) throws -> T {
        let url = URL(fileURLWithPath: path)
        let fileData = try Data(contentsOf: url, options: .uncached)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: fileData)
    }
}

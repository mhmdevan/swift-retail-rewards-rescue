import Foundation

public enum ModernHTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

public protocol ModernEndpoint {
    associatedtype Response: Decodable

    var path: String { get }
    var method: ModernHTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
}

public extension ModernEndpoint {
    var queryItems: [URLQueryItem] { [] }
    var headers: [String: String] { [:] }
}

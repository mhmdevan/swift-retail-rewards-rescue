import Foundation

public enum LegacyHTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

public struct LegacyNetworkRequest: Equatable, Sendable {
    public let path: String
    public let method: LegacyHTTPMethod
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let timeout: TimeInterval

    public init(
        path: String,
        method: LegacyHTTPMethod,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        timeout: TimeInterval = 15
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.timeout = timeout
    }
}

public struct LegacyNetworkResponse: Equatable, Sendable {
    public let statusCode: Int
    public let data: Data

    public init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }
}

public enum LegacyTransportError: Error, Equatable, Sendable {
    case notConnected
    case timedOut
    case cancelled
    case transport(message: String)
}

public protocol LegacyNetworkExecuting: Sendable {
    func execute(_ request: LegacyNetworkRequest) async throws -> LegacyNetworkResponse
}

import Core
import Foundation

public struct LegacyNetworkErrorMapper: Sendable {
    public init() {}

    public func map(transportError: LegacyTransportError) -> AppNetworkError {
        switch transportError {
        case .notConnected:
            return .connectivity
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        case let .transport(message):
            return .unknown(message: message)
        }
    }

    public func map(statusCode: Int) -> AppNetworkError {
        .server(statusCode: statusCode)
    }

    public func mapDecodingError() -> AppNetworkError {
        .decoding
    }
}

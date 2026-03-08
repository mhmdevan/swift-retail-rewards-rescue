import Foundation

public enum AppNetworkError: Error, Equatable, LocalizedError {
    case connectivity
    case timeout
    case cancelled
    case server(statusCode: Int)
    case requestConstruction
    case decoding
    case unknown(message: String)

    public var errorDescription: String? {
        switch self {
        case .connectivity:
            return "No internet connection. Check connectivity and try again."
        case .timeout:
            return "The request timed out. Please retry."
        case .cancelled:
            return "The request was canceled."
        case let .server(statusCode):
            return "Server error (\(statusCode)). Please try again."
        case .requestConstruction:
            return "Unable to build request."
        case .decoding:
            return "Unable to parse server response."
        case let .unknown(message):
            return message
        }
    }
}

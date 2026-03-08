import Core
import Foundation

public struct LegacyRetryPolicy: Sendable {
    public let maxRetryCount: Int

    public init(maxRetryCount: Int = 2) {
        self.maxRetryCount = maxRetryCount
    }

    public func shouldRetry(attempt: Int, for error: AppNetworkError) -> Bool {
        guard attempt < maxRetryCount else {
            return false
        }

        switch error {
        case .connectivity, .timeout:
            return true
        case let .server(statusCode):
            return (500 ... 599).contains(statusCode)
        default:
            return false
        }
    }
}

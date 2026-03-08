import Alamofire
import FeaturesOffers
import Foundation

final class AlamofireLegacyNetworkClient: LegacyNetworkExecuting {
    private let baseURL: URL
    private let session: Session

    init(baseURL: URL, session: Session = .default) {
        self.baseURL = baseURL
        self.session = session
    }

    func execute(_ request: LegacyNetworkRequest) async throws -> LegacyNetworkResponse {
        let urlRequest = try buildURLRequest(from: request)

        return try await withCheckedThrowingContinuation { continuation in
            session.request(urlRequest).responseData { response in
                if let afError = response.error {
                    continuation.resume(throwing: Self.mapTransportError(afError))
                    return
                }

                guard let httpResponse = response.response else {
                    continuation.resume(throwing: LegacyTransportError.transport(message: "Missing HTTP response"))
                    return
                }

                continuation.resume(
                    returning: LegacyNetworkResponse(
                        statusCode: httpResponse.statusCode,
                        data: response.data ?? Data()
                    )
                )
            }
        }
    }

    private func buildURLRequest(from request: LegacyNetworkRequest) throws -> URLRequest {
        let normalizedPath = request.path.hasPrefix("/") ? String(request.path.dropFirst()) : request.path

        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(normalizedPath),
            resolvingAgainstBaseURL: false
        ) else {
            throw LegacyTransportError.transport(message: "Failed to build URL components")
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw LegacyTransportError.transport(message: "Failed to build URL")
        }

        var urlRequest = URLRequest(url: url, timeoutInterval: request.timeout)
        urlRequest.httpMethod = request.method.rawValue

        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        return urlRequest
    }

    private static func mapTransportError(_ error: AFError) -> LegacyTransportError {
        if error.isExplicitlyCancelledError {
            return .cancelled
        }

        if let underlyingError = error.underlyingError as? URLError {
            switch underlyingError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .notConnected
            case .timedOut:
                return .timedOut
            case .cancelled:
                return .cancelled
            default:
                return .transport(message: underlyingError.localizedDescription)
            }
        }

        return .transport(message: error.localizedDescription)
    }
}

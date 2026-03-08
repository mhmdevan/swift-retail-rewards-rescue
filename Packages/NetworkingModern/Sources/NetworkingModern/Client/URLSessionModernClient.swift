import Core
import Foundation

public final class URLSessionModernClient: ModernNetworkingClient {
    private let baseURL: URL
    private let session: any URLSessionDataLoading
    private let decoder: JSONDecoder

    public init(
        baseURL: URL,
        session: any URLSessionDataLoading = URLSession.shared,
        decoder: JSONDecoder = .init()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    public func send<Endpoint: ModernEndpoint>(_ endpoint: Endpoint) async throws -> Endpoint.Response {
        let request: URLRequest
        do {
            request = try buildRequest(endpoint: endpoint)
        } catch {
            throw AppNetworkError.requestConstruction
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw mapTransport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppNetworkError.unknown(message: "Invalid HTTP response")
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw AppNetworkError.server(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(Endpoint.Response.self, from: data)
        } catch {
            throw AppNetworkError.decoding
        }
    }

    private func buildRequest<Endpoint: ModernEndpoint>(endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw AppNetworkError.requestConstruction
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw AppNetworkError.requestConstruction
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func mapTransport(_ error: Error) -> AppNetworkError {
        guard let urlError = error as? URLError else {
            return .unknown(message: error.localizedDescription)
        }

        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .connectivity
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .unknown(message: urlError.localizedDescription)
        }
    }
}

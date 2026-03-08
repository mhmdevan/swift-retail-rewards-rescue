import Foundation

public protocol ModernNetworkingClient: Sendable {
    func send<Endpoint: ModernEndpoint>(_ endpoint: Endpoint) async throws -> Endpoint.Response
}

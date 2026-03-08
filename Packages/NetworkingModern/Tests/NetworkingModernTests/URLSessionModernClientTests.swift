import Core
import Foundation
import Testing
@testable import NetworkingModern

private struct PingResponse: Decodable, Equatable {
    let status: String
}

private struct PingEndpoint: ModernEndpoint {
    typealias Response = PingResponse

    let path: String = "/health"
    let method: ModernHTTPMethod = .get
}

@Test func sendDecodesSuccessfulResponse() async throws {
    let session = MockURLSession(
        result: .success(
            (
                Data("{\"status\":\"ok\"}".utf8),
                HTTPURLResponse(
                    url: URL(string: "https://modern.retailrewardsrescue.local/health")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
            )
        )
    )

    let client = URLSessionModernClient(
        baseURL: URL(string: "https://modern.retailrewardsrescue.local")!,
        session: session
    )

    let response = try await client.send(PingEndpoint())

    #expect(response == PingResponse(status: "ok"))
}

@Test func sendMapsServerErrorStatusCode() async {
    let session = MockURLSession(
        result: .success(
            (
                Data(),
                HTTPURLResponse(
                    url: URL(string: "https://modern.retailrewardsrescue.local/health")!,
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: nil
                )!
            )
        )
    )

    let client = URLSessionModernClient(
        baseURL: URL(string: "https://modern.retailrewardsrescue.local")!,
        session: session
    )

    await #expect(throws: AppNetworkError.server(statusCode: 503)) {
        _ = try await client.send(PingEndpoint())
    }
}

@Test func sendMapsTimeoutTransportError() async {
    let session = MockURLSession(
        result: .failure(URLError(.timedOut))
    )

    let client = URLSessionModernClient(
        baseURL: URL(string: "https://modern.retailrewardsrescue.local")!,
        session: session
    )

    await #expect(throws: AppNetworkError.timeout) {
        _ = try await client.send(PingEndpoint())
    }
}

private struct MockURLSession: URLSessionDataLoading {
    let result: Result<(Data, URLResponse), Error>

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try result.get()
    }
}

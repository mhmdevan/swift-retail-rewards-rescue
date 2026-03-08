import Core
import FeaturesOffers
import Foundation
import Testing
@testable import NetworkingModern

@Test func fetchOffersMapsDTOIntoSharedOfferSummary() async throws {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let client = MockModernNetworkingClient(
        result: .success(
            Data(
                """
                {
                  "items": [
                    {
                      "id": "modern-offer-1",
                      "title": "Modern 15% Off",
                      "subtitle": "URLSession path",
                      "image_url": "https://img.example.com/modern.png",
                      "expiry_date": "2026-12-20T00:00:00Z"
                    }
                  ]
                }
                """.utf8
            )
        ),
        decoder: decoder
    )

    let repository = ModernOffersRepository(client: client)

    let offers = try await repository.fetchOffers(page: 1, pageSize: 10)

    #expect(offers.count == 1)
    #expect(offers[0].id == "modern-offer-1")
    #expect(offers[0].title == "Modern 15% Off")
}

@Test func fetchOffersPropagatesNormalizedError() async {
    let client = MockModernNetworkingClient(result: .failure(AppNetworkError.connectivity), decoder: JSONDecoder())
    let repository = ModernOffersRepository(client: client)

    await #expect(throws: AppNetworkError.connectivity) {
        _ = try await repository.fetchOffers(page: 1, pageSize: 20)
    }
}

private struct MockModernNetworkingClient: ModernNetworkingClient {
    let result: Result<Data, Error>
    let decoder: JSONDecoder

    func send<Endpoint>(_ endpoint: Endpoint) async throws -> Endpoint.Response where Endpoint: ModernEndpoint {
        let data = try result.get()
        return try decoder.decode(Endpoint.Response.self, from: data)
    }
}

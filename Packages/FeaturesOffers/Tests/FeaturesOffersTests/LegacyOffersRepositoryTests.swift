import Core
import Foundation
import Testing
@testable import FeaturesOffers

@Test func fetchOffersMapsResponseDTOIntoOfferSummaries() async throws {
    let network = MockLegacyNetworkClient(
        queuedResults: [
            .success(
                LegacyNetworkResponse(
                    statusCode: 200,
                    data: makeResponseData(
                        """
                        {
                          "offers": [
                            {
                              "id": "offer-1",
                              "title": "10% Off Groceries",
                              "subtitle": "Weekend members only",
                              "image_url": "https://img.example.com/1.png",
                              "expiry_date": "2026-12-01T00:00:00Z"
                            }
                          ]
                        }
                        """
                    )
                )
            )
        ]
    )

    let repository = LegacyOffersRepository(network: network)

    let offers = try await repository.fetchOffers(page: 1, pageSize: 20)

    #expect(offers.count == 1)
    #expect(offers.first?.id == "offer-1")
    #expect(offers.first?.title == "10% Off Groceries")
    #expect(await network.executedRequestCount() == 1)
}

@Test func fetchOffersRetriesAfterTimeoutAndThenSucceeds() async throws {
    let network = MockLegacyNetworkClient(
        queuedResults: [
            .failure(.timedOut),
            .success(
                LegacyNetworkResponse(
                    statusCode: 200,
                    data: makeResponseData(
                        """
                        {
                          "offers": [
                            {
                              "id": "offer-2",
                              "title": "2x Points",
                              "subtitle": "For app pay",
                              "image_url": null,
                              "expiry_date": "2026-12-10T00:00:00Z"
                            }
                          ]
                        }
                        """
                    )
                )
            )
        ]
    )

    let repository = LegacyOffersRepository(
        network: network,
        retryPolicy: LegacyRetryPolicy(maxRetryCount: 2)
    )

    let offers = try await repository.fetchOffers(page: 1, pageSize: 20)

    #expect(offers.count == 1)
    #expect(offers.first?.id == "offer-2")
    #expect(await network.executedRequestCount() == 2)
}

@Test func fetchOffersReturnsNormalizedServerErrorAfterRetryBudget() async {
    let network = MockLegacyNetworkClient(
        queuedResults: [
            .success(LegacyNetworkResponse(statusCode: 503, data: Data())),
            .success(LegacyNetworkResponse(statusCode: 503, data: Data())),
            .success(LegacyNetworkResponse(statusCode: 503, data: Data()))
        ]
    )

    let repository = LegacyOffersRepository(
        network: network,
        retryPolicy: LegacyRetryPolicy(maxRetryCount: 2)
    )

    await #expect(throws: AppNetworkError.server(statusCode: 503)) {
        _ = try await repository.fetchOffers(page: 1, pageSize: 20)
    }

    #expect(await network.executedRequestCount() == 3)
}

@Test func fetchOffersMapsInvalidJSONToDecodingError() async {
    let network = MockLegacyNetworkClient(
        queuedResults: [
            .success(LegacyNetworkResponse(statusCode: 200, data: Data("{}".utf8)))
        ]
    )

    let repository = LegacyOffersRepository(network: network)

    await #expect(throws: AppNetworkError.decoding) {
        _ = try await repository.fetchOffers(page: 1, pageSize: 20)
    }
}

@Test func requestBuilderBuildsLegacyOffersRequest() {
    let builder = LegacyOffersRequestBuilder()

    let request = builder.makeFetchOffersRequest(page: 3, pageSize: 50)

    #expect(request.path == "/legacy/v1/offers")
    #expect(request.method == .get)
    #expect(request.queryItems.contains(URLQueryItem(name: "page", value: "3")))
    #expect(request.queryItems.contains(URLQueryItem(name: "pageSize", value: "50")))
}

private actor MockLegacyNetworkClient: LegacyNetworkExecuting {
    private var queuedResults: [Result<LegacyNetworkResponse, LegacyTransportError>]
    private var requests: [LegacyNetworkRequest] = []

    init(queuedResults: [Result<LegacyNetworkResponse, LegacyTransportError>]) {
        self.queuedResults = queuedResults
    }

    func execute(_ request: LegacyNetworkRequest) async throws -> LegacyNetworkResponse {
        requests.append(request)

        if queuedResults.isEmpty {
            throw LegacyTransportError.transport(message: "No mock response queued.")
        }

        let result = queuedResults.removeFirst()
        return try result.get()
    }

    func executedRequestCount() -> Int {
        requests.count
    }
}

private func makeResponseData(_ rawJSON: String) -> Data {
    Data(rawJSON.utf8)
}

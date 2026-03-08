import Foundation

public protocol LegacyOffersRequestBuilding: Sendable {
    func makeFetchOffersRequest(page: Int, pageSize: Int) -> LegacyNetworkRequest
}

public struct LegacyOffersRequestBuilder: LegacyOffersRequestBuilding {
    public init() {}

    public func makeFetchOffersRequest(page: Int, pageSize: Int) -> LegacyNetworkRequest {
        LegacyNetworkRequest(
            path: "/legacy/v1/offers",
            method: .get,
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "pageSize", value: String(pageSize))
            ],
            headers: [
                "Accept": "application/json"
            ]
        )
    }
}

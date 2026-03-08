import Core
import FeaturesOffers
import Foundation

private struct ModernOffersEnvelopeDTO: Decodable {
    let items: [ModernOfferDTO]
}

private struct ModernOfferDTO: Decodable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
    let expiryDate: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case imageURL = "image_url"
        case expiryDate = "expiry_date"
    }
}

private struct ModernOffersEndpoint: ModernEndpoint {
    typealias Response = ModernOffersEnvelopeDTO

    let page: Int
    let pageSize: Int

    var path: String { "/modern/v1/offers" }
    var method: ModernHTTPMethod { .get }
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]
    }

    var headers: [String: String] {
        ["Accept": "application/json"]
    }
}

public final class ModernOffersRepository: OffersRepository {
    private let client: any ModernNetworkingClient

    public init(client: any ModernNetworkingClient) {
        self.client = client
    }

    public func fetchOffers(page: Int, pageSize: Int) async throws -> [OfferSummary] {
        let endpoint = ModernOffersEndpoint(page: page, pageSize: pageSize)
        let response = try await client.send(endpoint)

        return response.items.map {
            OfferSummary(
                id: $0.id,
                title: $0.title,
                subtitle: $0.subtitle,
                imageURL: $0.imageURL,
                expiryDate: $0.expiryDate
            )
        }
    }
}

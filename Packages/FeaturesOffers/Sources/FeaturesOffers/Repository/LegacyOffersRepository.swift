import Core
import Foundation

private struct LegacyOffersEnvelopeDTO: Decodable {
    let offers: [LegacyOfferDTO]
}

private struct LegacyOfferDTO: Decodable {
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

public final class LegacyOffersRepository: OffersRepository {
    private let network: any LegacyNetworkExecuting
    private let requestBuilder: any LegacyOffersRequestBuilding
    private let errorMapper: LegacyNetworkErrorMapper
    private let retryPolicy: LegacyRetryPolicy
    private let decoder: JSONDecoder

    public init(
        network: any LegacyNetworkExecuting,
        requestBuilder: any LegacyOffersRequestBuilding = LegacyOffersRequestBuilder(),
        errorMapper: LegacyNetworkErrorMapper = .init(),
        retryPolicy: LegacyRetryPolicy = .init(),
        decoder: JSONDecoder? = nil
    ) {
        self.network = network
        self.requestBuilder = requestBuilder
        self.errorMapper = errorMapper
        self.retryPolicy = retryPolicy
        self.decoder = decoder ?? Self.makeDefaultDecoder()
    }

    public func fetchOffers(page: Int, pageSize: Int) async throws -> [OfferSummary] {
        let request = requestBuilder.makeFetchOffersRequest(page: page, pageSize: pageSize)
        var attempt = 0

        while true {
            do {
                let response = try await network.execute(request)

                guard (200 ... 299).contains(response.statusCode) else {
                    let mappedError = errorMapper.map(statusCode: response.statusCode)
                    if retryPolicy.shouldRetry(attempt: attempt, for: mappedError) {
                        attempt += 1
                        continue
                    }
                    throw mappedError
                }

                do {
                    let decoded = try decoder.decode(LegacyOffersEnvelopeDTO.self, from: response.data)
                    return decoded.offers.map {
                        OfferSummary(
                            id: $0.id,
                            title: $0.title,
                            subtitle: $0.subtitle,
                            imageURL: $0.imageURL,
                            expiryDate: $0.expiryDate
                        )
                    }
                } catch {
                    throw errorMapper.mapDecodingError()
                }
            } catch let transportError as LegacyTransportError {
                let mappedError = errorMapper.map(transportError: transportError)
                if retryPolicy.shouldRetry(attempt: attempt, for: mappedError) {
                    attempt += 1
                    continue
                }
                throw mappedError
            } catch let appError as AppNetworkError {
                throw appError
            } catch {
                throw AppNetworkError.unknown(message: error.localizedDescription)
            }
        }
    }

    private static func makeDefaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

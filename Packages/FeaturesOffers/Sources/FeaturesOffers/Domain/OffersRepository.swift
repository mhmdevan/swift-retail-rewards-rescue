import Foundation

public protocol OffersRepository: Sendable {
    func fetchOffers(page: Int, pageSize: Int) async throws -> [OfferSummary]
}

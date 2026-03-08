import FeaturesOffers
import Foundation

public enum SavedOfferToggleError: Error, Equatable {
    case cannotSaveExpiredOffer
}

public struct SavedOffersStateService {
    public init() {}

    public func mergeSavedAndExpiryState(
        offers: [OfferSummary],
        savedIDs: Set<String>,
        referenceDate: Date
    ) -> [OfferSummary] {
        offers.map { offer in
            OfferSummary(
                id: offer.id,
                title: offer.title,
                subtitle: offer.subtitle,
                imageURL: offer.imageURL,
                expiryDate: offer.expiryDate,
                isSaved: savedIDs.contains(offer.id),
                isExpired: offer.expiryDate < referenceDate
            )
        }
    }

    public func toggleSavedState(for offer: OfferSummary) throws -> OfferSummary {
        if !offer.isSaved, offer.isExpired {
            throw SavedOfferToggleError.cannotSaveExpiredOffer
        }

        return OfferSummary(
            id: offer.id,
            title: offer.title,
            subtitle: offer.subtitle,
            imageURL: offer.imageURL,
            expiryDate: offer.expiryDate,
            isSaved: !offer.isSaved,
            isExpired: offer.isExpired
        )
    }
}

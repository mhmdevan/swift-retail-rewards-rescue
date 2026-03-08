import FeaturesOffers
import FeaturesSavedOffers
import Foundation
import Persistence

enum OfferSaveError: LocalizedError, Equatable {
    case expiredOfferCannotBeSaved

    var errorDescription: String? {
        switch self {
        case .expiredOfferCannotBeSaved:
            return "This offer has expired and can no longer be saved."
        }
    }
}

final class OfferSaveService {
    private let store: any SavedOffersStoring
    private let stateService = SavedOffersStateService()

    init(store: any SavedOffersStoring) {
        self.store = store
    }

    func reconcileExpiry(referenceDate: Date = Date()) throws -> [String] {
        try store.reconcileExpiredOffers(referenceDate: referenceDate)
    }

    func applySavedAndExpiryState(to offer: OfferSummary, referenceDate: Date = Date()) -> OfferSummary {
        stateService.mergeSavedAndExpiryState(
            offers: [offer],
            savedIDs: (try? store.fetchSavedOfferIDs()) ?? [],
            referenceDate: referenceDate
        )
        .first ?? offer
    }

    func toggleSave(for offer: OfferSummary, referenceDate: Date = Date()) throws -> OfferSummary {
        let normalizedOffer = applySavedAndExpiryState(to: offer, referenceDate: referenceDate)

        if normalizedOffer.isSaved {
            try store.unsave(offerID: normalizedOffer.id)
            return try stateService.toggleSavedState(for: normalizedOffer)
        }

        let toggled: OfferSummary
        do {
            toggled = try stateService.toggleSavedState(for: normalizedOffer)
        } catch SavedOfferToggleError.cannotSaveExpiredOffer {
            throw OfferSaveError.expiredOfferCannotBeSaved
        }

        try store.save(toggled)
        return toggled
    }
}

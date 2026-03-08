import FeaturesOffers
import Foundation
import Testing
@testable import FeaturesSavedOffers

@Test func mergeSavedAndExpiryStateAppliesBothFlags() {
    let service = SavedOffersStateService()
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    let offers = [
        OfferSummary(
            id: "saved-active",
            title: "A",
            subtitle: "A",
            imageURL: nil,
            expiryDate: Date(timeIntervalSince1970: 1_800_000_000)
        ),
        OfferSummary(
            id: "unsaved-expired",
            title: "B",
            subtitle: "B",
            imageURL: nil,
            expiryDate: Date(timeIntervalSince1970: 1_600_000_000)
        )
    ]

    let merged = service.mergeSavedAndExpiryState(
        offers: offers,
        savedIDs: ["saved-active"],
        referenceDate: now
    )

    #expect(merged[0].isSaved == true)
    #expect(merged[0].isExpired == false)
    #expect(merged[1].isSaved == false)
    #expect(merged[1].isExpired == true)
}

@Test func toggleSavedStateUnsavesWhenCurrentlySaved() throws {
    let service = SavedOffersStateService()
    let offer = OfferSummary(
        id: "saved",
        title: "A",
        subtitle: "A",
        imageURL: nil,
        expiryDate: Date(),
        isSaved: true,
        isExpired: false
    )

    let toggled = try service.toggleSavedState(for: offer)

    #expect(toggled.isSaved == false)
}

@Test func toggleSavedStateThrowsForExpiredUnsavedOffer() {
    let service = SavedOffersStateService()
    let offer = OfferSummary(
        id: "expired",
        title: "A",
        subtitle: "A",
        imageURL: nil,
        expiryDate: Date(),
        isSaved: false,
        isExpired: true
    )

    #expect(throws: SavedOfferToggleError.cannotSaveExpiredOffer) {
        _ = try service.toggleSavedState(for: offer)
    }
}

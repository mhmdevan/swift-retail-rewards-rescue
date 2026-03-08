import FeaturesOffers
import Foundation
import Testing
@testable import Persistence

@Test func saveAndFetchSavedOffersRoundTripsData() throws {
    let stack = PersistenceCoreDataStack(inMemory: true)
    let store = CoreDataSavedOffersStore(stack: stack)
    let offer = OfferSummary(
        id: "offer-1",
        title: "Discount",
        subtitle: "Save now",
        imageURL: URL(string: "https://example.com/1.png"),
        expiryDate: Date(timeIntervalSince1970: 1_800_000_000)
    )

    try store.save(offer)
    let fetched = try store.fetchSavedOffers(sortedBy: .savedDateDescending)

    #expect(fetched.count == 1)
    #expect(fetched.first?.id == "offer-1")
}

@Test func unsaveRemovesOffer() throws {
    let stack = PersistenceCoreDataStack(inMemory: true)
    let store = CoreDataSavedOffersStore(stack: stack)
    let offer = OfferSummary(
        id: "offer-2",
        title: "Bonus",
        subtitle: "Weekend",
        imageURL: nil,
        expiryDate: Date(timeIntervalSince1970: 1_800_000_000)
    )

    try store.save(offer)
    try store.unsave(offerID: "offer-2")

    #expect(try store.isSaved(offerID: "offer-2") == false)
}

@Test func fetchSavedOfferIDsReturnsDistinctSavedIDs() throws {
    let stack = PersistenceCoreDataStack(inMemory: true)
    let store = CoreDataSavedOffersStore(stack: stack)

    try store.save(
        OfferSummary(
            id: "offer-a",
            title: "A",
            subtitle: "A",
            imageURL: nil,
            expiryDate: Date(timeIntervalSince1970: 1_900_000_000)
        )
    )
    try store.save(
        OfferSummary(
            id: "offer-b",
            title: "B",
            subtitle: "B",
            imageURL: nil,
            expiryDate: Date(timeIntervalSince1970: 1_900_000_100)
        )
    )

    let ids = try store.fetchSavedOfferIDs()

    #expect(ids == ["offer-a", "offer-b"])
}

@Test func reconcileExpiredOffersDeletesExpiredRecords() throws {
    let stack = PersistenceCoreDataStack(inMemory: true)
    let store = CoreDataSavedOffersStore(stack: stack)

    try store.save(
        OfferSummary(
            id: "expired",
            title: "Old",
            subtitle: "Old",
            imageURL: nil,
            expiryDate: Date(timeIntervalSince1970: 1_600_000_000)
        )
    )
    try store.save(
        OfferSummary(
            id: "active",
            title: "Active",
            subtitle: "Current",
            imageURL: nil,
            expiryDate: Date(timeIntervalSince1970: 1_900_000_000)
        )
    )

    let removed = try store.reconcileExpiredOffers(referenceDate: Date(timeIntervalSince1970: 1_700_000_000))

    #expect(removed == ["expired"])
    #expect(try store.isSaved(offerID: "expired") == false)
    #expect(try store.isSaved(offerID: "active") == true)
}

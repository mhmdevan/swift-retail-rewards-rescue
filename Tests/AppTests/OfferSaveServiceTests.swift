import FeaturesOffers
import Persistence
import XCTest
@testable import RetailRewardsRescue

final class OfferSaveServiceTests: XCTestCase {
    private var stack: PersistenceCoreDataStack!
    private var store: CoreDataSavedOffersStore!
    private var sut: OfferSaveService!

    override func setUp() {
        super.setUp()
        stack = PersistenceCoreDataStack(inMemory: true)
        store = CoreDataSavedOffersStore(stack: stack)
        sut = OfferSaveService(store: store)
    }

    override func tearDown() {
        sut = nil
        store = nil
        stack = nil
        super.tearDown()
    }

    func testToggleSavePersistsUnsavedOffer() throws {
        let offer = OfferSummary(
            id: "offer-1",
            title: "Offer 1",
            subtitle: "Subtitle",
            imageURL: nil,
            expiryDate: Date().addingTimeInterval(3600),
            isSaved: false,
            isExpired: false
        )

        let updated = try sut.toggleSave(for: offer)

        XCTAssertTrue(updated.isSaved)
        XCTAssertTrue(try store.isSaved(offerID: offer.id))
    }

    func testToggleSaveThrowsForExpiredUnsavedOffer() throws {
        let offer = OfferSummary(
            id: "offer-2",
            title: "Offer 2",
            subtitle: "Subtitle",
            imageURL: nil,
            expiryDate: Date().addingTimeInterval(-60),
            isSaved: false,
            isExpired: true
        )

        XCTAssertThrowsError(try sut.toggleSave(for: offer)) { error in
            XCTAssertEqual(error as? OfferSaveError, .expiredOfferCannotBeSaved)
        }
    }

    func testToggleSaveUnsavesPreviouslySavedOffer() throws {
        let offer = OfferSummary(
            id: "offer-3",
            title: "Offer 3",
            subtitle: "Subtitle",
            imageURL: nil,
            expiryDate: Date().addingTimeInterval(3600),
            isSaved: false,
            isExpired: false
        )

        _ = try sut.toggleSave(for: offer)
        let unsaved = try sut.toggleSave(for: offer.withSavedState())

        XCTAssertFalse(unsaved.isSaved)
        XCTAssertFalse(try store.isSaved(offerID: offer.id))
    }
}

private extension OfferSummary {
    func withSavedState() -> OfferSummary {
        OfferSummary(
            id: id,
            title: title,
            subtitle: subtitle,
            imageURL: imageURL,
            expiryDate: expiryDate,
            isSaved: true,
            isExpired: isExpired
        )
    }
}

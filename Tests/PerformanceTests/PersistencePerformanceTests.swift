import FeaturesOffers
import Persistence
import XCTest

final class PersistencePerformanceTests: XCTestCase {
    func testSavedOffersFetchLatency() throws {
        let stack = PersistenceCoreDataStack(inMemory: true)
        let store = CoreDataSavedOffersStore(stack: stack)

        for index in 0..<250 {
            try store.save(
                OfferSummary(
                    id: "offer-\(index)",
                    title: "Offer \(index)",
                    subtitle: "Subtitle \(index)",
                    imageURL: nil,
                    expiryDate: Date().addingTimeInterval(86_400)
                )
            )
        }

        measure {
            _ = try? store.fetchSavedOffers(sortedBy: .savedDateDescending)
        }
    }

    func testExpiryReconciliationPerformance() throws {
        let stack = PersistenceCoreDataStack(inMemory: true)
        let store = CoreDataSavedOffersStore(stack: stack)

        for index in 0..<250 {
            let expiryDate = index % 2 == 0
                ? Date().addingTimeInterval(-100)
                : Date().addingTimeInterval(1_000)
            try store.save(
                OfferSummary(
                    id: "exp-offer-\(index)",
                    title: "Offer \(index)",
                    subtitle: "Subtitle \(index)",
                    imageURL: nil,
                    expiryDate: expiryDate
                )
            )
        }

        measure {
            _ = try? store.reconcileExpiredOffers(referenceDate: Date())
        }
    }
}

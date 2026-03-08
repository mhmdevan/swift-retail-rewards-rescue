import CoreData
import Core
import DesignSystem
import FeaturesOffers
import Persistence
import RxBlocking
import RxSwift
import RxTest
import XCTest
@testable import RetailRewardsRescue

final class OffersFeedViewModelRxTests: XCTestCase {
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }

    func testPaginationMergesWithoutDuplicates() {
        let repository = StubOffersRepository(
            pages: [
                1: [
                    OfferSummary(
                        id: "offer-1",
                        title: "Offer 1",
                        subtitle: "S1",
                        imageURL: nil,
                        expiryDate: Date().addingTimeInterval(3600)
                    ),
                    OfferSummary(
                        id: "offer-2",
                        title: "Offer 2",
                        subtitle: "S2",
                        imageURL: nil,
                        expiryDate: Date().addingTimeInterval(3600)
                    )
                ],
                2: [
                    OfferSummary(
                        id: "offer-2",
                        title: "Offer 2",
                        subtitle: "S2",
                        imageURL: nil,
                        expiryDate: Date().addingTimeInterval(3600)
                    ),
                    OfferSummary(
                        id: "offer-3",
                        title: "Offer 3",
                        subtitle: "S3",
                        imageURL: nil,
                        expiryDate: Date().addingTimeInterval(3600)
                    )
                ]
            ]
        )
        let savedStore = StubSavedOffersStore(savedIDs: ["offer-1"])
        let viewModel = OffersFeedViewModel(
            repository: repository,
            savedOffersStore: savedStore,
            schedulers: ImmediateSchedulerProvider(),
            pageSize: 2
        )

        let initialLoad = PublishSubject<Void>()
        let nextPage = PublishSubject<Void>()
        let output = viewModel.transform(
            input: .init(
                initialLoad: initialLoad.asObservable(),
                pullToRefresh: .empty(),
                retryTap: .empty(),
                loadNextPage: nextPage.asObservable()
            )
        )

        var latest: [OfferSummary] = []
        let mergedExpectation = expectation(description: "Merged pagination result emitted")
        output.offers
            .drive(onNext: { offers in
                latest = offers
                if offers.count == 3 {
                    mergedExpectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        initialLoad.onNext(())
        nextPage.onNext(())

        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(latest.map(\.id), ["offer-1", "offer-2", "offer-3"])
        XCTAssertEqual(repository.requestedPages, [1, 2])
    }

    func testRetryFlowMovesFromErrorToContent() {
        let repository = StubOffersRepository(
            pages: [
                1: [
                    OfferSummary(
                        id: "offer-1",
                        title: "Offer 1",
                        subtitle: "S1",
                        imageURL: nil,
                        expiryDate: Date().addingTimeInterval(3600)
                    )
                ]
            ],
            failFirstRequestForPage1: true
        )
        let savedStore = StubSavedOffersStore(savedIDs: [])
        let scheduler = TestScheduler(initialClock: 0)
        let viewModel = OffersFeedViewModel(
            repository: repository,
            savedOffersStore: savedStore,
            schedulers: ImmediateSchedulerProvider(),
            pageSize: 1
        )

        let initialLoad = scheduler.createHotObservable([.next(10, ())]).asObservable()
        let retryTap = scheduler.createHotObservable([.next(20, ())]).asObservable()
        let output = viewModel.transform(
            input: .init(
                initialLoad: initialLoad,
                pullToRefresh: .empty(),
                retryTap: retryTap,
                loadNextPage: .empty()
            )
        )

        let stateObserver = scheduler.createObserver(ContentState.self)
        output.state.drive(stateObserver).disposed(by: disposeBag)
        scheduler.start()

        let contentState = try? output.state
            .asObservable()
            .filter { $0 == .content }
            .take(1)
            .toBlocking(timeout: 2.0)
            .first()

        XCTAssertEqual(repository.requestedPages, [1, 1])
        XCTAssertEqual(contentState, .content)
        XCTAssertTrue(
            stateObserver.events.contains(where: {
                if case .error = $0.value.element {
                    return true
                }
                return false
            })
        )
    }
}

private final class StubOffersRepository: OffersRepository {
    private let lock = NSLock()
    private let pages: [Int: [OfferSummary]]
    private var failFirstRequestForPage1: Bool

    private(set) var requestedPages: [Int] = []

    init(
        pages: [Int: [OfferSummary]],
        failFirstRequestForPage1: Bool = false
    ) {
        self.pages = pages
        self.failFirstRequestForPage1 = failFirstRequestForPage1
    }

    func fetchOffers(page: Int, pageSize: Int) async throws -> [OfferSummary] {
        lock.lock()
        requestedPages.append(page)
        let shouldFail = page == 1 && failFirstRequestForPage1
        if shouldFail {
            failFirstRequestForPage1 = false
        }
        lock.unlock()

        if shouldFail {
            throw AppNetworkError.server(statusCode: 500, message: "stub fail")
        }

        return pages[page] ?? []
    }
}

private final class StubSavedOffersStore: SavedOffersStoring {
    private let savedIDs: Set<String>

    init(savedIDs: Set<String>) {
        self.savedIDs = savedIDs
    }

    func save(_ offer: OfferSummary) throws {}

    func unsave(offerID: String) throws {}

    func isSaved(offerID: String) throws -> Bool {
        savedIDs.contains(offerID)
    }

    func fetchSavedOfferIDs() throws -> Set<String> {
        savedIDs
    }

    func fetchSavedOffers(sortedBy: SavedOffersSortOption) throws -> [OfferSummary] {
        []
    }

    func reconcileExpiredOffers(referenceDate: Date) throws -> [String] {
        []
    }

    func makeFetchedResultsController(sortedBy: SavedOffersSortOption) -> NSFetchedResultsController<NSManagedObject> {
        fatalError("Not needed in view model tests")
    }
}

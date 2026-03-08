import CoreData
import Core
import DesignSystem
import FeaturesOffers
import Persistence
import RxSwift
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
        var didRequestSecondPage = false
        let mergedExpectation = expectation(description: "Merged pagination result emitted")
        output.offers
            .drive(onNext: { [weak nextPage] offers in
                latest = offers
                if offers.count == 2, !didRequestSecondPage {
                    didRequestSecondPage = true
                    DispatchQueue.main.async {
                        nextPage?.onNext(())
                    }
                }
                if offers.count == 3 {
                    mergedExpectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        initialLoad.onNext(())

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
        let viewModel = OffersFeedViewModel(
            repository: repository,
            savedOffersStore: savedStore,
            schedulers: ImmediateSchedulerProvider(),
            pageSize: 1
        )

        let initialLoad = PublishSubject<Void>()
        let retryTap = PublishSubject<Void>()
        let output = viewModel.transform(
            input: .init(
                initialLoad: initialLoad.asObservable(),
                pullToRefresh: .empty(),
                retryTap: retryTap.asObservable(),
                loadNextPage: .empty()
            )
        )

        var sawError = false
        let contentExpectation = expectation(description: "Content state emitted after retry")
        output.state
            .drive(onNext: { state in
                switch state {
                case .error:
                    if !sawError {
                        sawError = true
                        DispatchQueue.main.async {
                            retryTap.onNext(())
                        }
                    }
                case .content:
                    contentExpectation.fulfill()
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        initialLoad.onNext(())
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(repository.requestedPages, [1, 1])
        XCTAssertTrue(sawError)
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

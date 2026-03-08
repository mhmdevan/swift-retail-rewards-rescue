import Core
import DesignSystem
import FeaturesOffers
import Foundation
import Persistence
import RxCocoa
import RxSwift

final class OffersFeedViewModel: ReactiveViewModelType {
    struct Input {
        let initialLoad: Observable<Void>
        let pullToRefresh: Observable<Void>
        let retryTap: Observable<Void>
        let loadNextPage: Observable<Void>
    }

    struct Output {
        let offers: Driver<[OfferSummary]>
        let state: Driver<ContentState>
        let endRefreshing: Signal<Void>
        let isPaginating: Driver<Bool>
    }

    private enum LoadIntent: Equatable {
        case refresh
        case nextPage
    }

    private struct LoadPayload {
        let page: Int
        let offers: [OfferSummary]
    }

    private let repository: any OffersRepository
    private let savedOffersStore: any SavedOffersStoring
    private let schedulers: SchedulerProviding
    private let pageSize: Int

    private let disposeBag = DisposeBag()
    private var currentPage = 0
    private var hasMorePages = true
    private var isLoading = false

    init(
        repository: any OffersRepository,
        savedOffersStore: any SavedOffersStoring,
        schedulers: SchedulerProviding,
        pageSize: Int = 20
    ) {
        self.repository = repository
        self.savedOffersStore = savedOffersStore
        self.schedulers = schedulers
        self.pageSize = pageSize
    }

    func transform(input: Input) -> Output {
        let offersRelay = BehaviorRelay<[OfferSummary]>(value: [])
        let stateRelay = BehaviorRelay<ContentState>(value: .loading(message: "Loading offers..."))
        let endRefreshingRelay = PublishRelay<Void>()
        let isPaginatingRelay = BehaviorRelay<Bool>(value: false)

        let refreshTrigger = Observable.merge(input.initialLoad, input.pullToRefresh, input.retryTap)
            .map { LoadIntent.refresh }
        let nextPageTrigger = input.loadNextPage.map { LoadIntent.nextPage }

        Observable.merge(refreshTrigger, nextPageTrigger)
            .observe(on: schedulers.main)
            .filter { [weak self] intent in
                guard let self else { return false }
                if self.isLoading {
                    return false
                }
                if intent == .nextPage, !self.hasMorePages {
                    return false
                }
                return true
            }
            .do(onNext: { [weak self] intent in
                guard let self else { return }
                self.isLoading = true
                if intent == .refresh {
                    self.currentPage = 0
                    self.hasMorePages = true
                    stateRelay.accept(.loading(message: "Loading offers..."))
                    isPaginatingRelay.accept(false)
                } else {
                    isPaginatingRelay.accept(true)
                }
            })
            .observe(on: schedulers.background)
            .flatMapLatest { [weak self] intent -> Observable<Event<(LoadIntent, LoadPayload)>> in
                guard let self else {
                    return .empty()
                }

                let targetPage = intent == .refresh ? 1 : self.currentPage + 1
                return Self.fetchOffers(repository: self.repository, page: targetPage, pageSize: self.pageSize)
                    .map { (intent, $0) }
                    .materialize()
            }
            .observe(on: schedulers.main)
            .subscribe(onNext: { [weak self] event in
                guard let self else { return }

                switch event {
                case let .next((intent, payload)):
                    AppLogger.shared.debug(
                        "Offers page loaded",
                        category: .offers,
                        metadata: [
                            "intent": "\(intent)",
                            "page": "\(payload.page)",
                            "items": "\(payload.offers.count)"
                        ]
                    )
                    let enriched = self.enrichOffers(payload.offers)

                    if intent == .refresh {
                        offersRelay.accept(enriched)
                    } else {
                        let existing = offersRelay.value
                        let merged = self.mergeWithoutDuplicates(existing: existing, incoming: enriched)
                        offersRelay.accept(merged)
                    }

                    self.currentPage = payload.page
                    self.hasMorePages = payload.offers.count == self.pageSize

                    if offersRelay.value.isEmpty {
                        stateRelay.accept(
                            .empty(
                                title: "No offers available",
                                message: "Pull to refresh later for new personalized offers."
                            )
                        )
                    } else {
                        stateRelay.accept(.content)
                    }

                case let .error(error):
                    let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    AppLogger.shared.error(
                        "Offers load failed",
                        category: .offers,
                        metadata: ["message": message]
                    )
                    if offersRelay.value.isEmpty {
                        stateRelay.accept(
                            .error(
                                title: "Failed to load offers",
                                message: message,
                                retryTitle: "Retry"
                            )
                        )
                    }

                case .completed:
                    break
                }

                self.isLoading = false
                isPaginatingRelay.accept(false)
                endRefreshingRelay.accept(())
            })
            .disposed(by: disposeBag)

        return Output(
            offers: offersRelay.asDriver(),
            state: stateRelay.asDriver(),
            endRefreshing: endRefreshingRelay.asSignal(),
            isPaginating: isPaginatingRelay.asDriver()
        )
    }

    private static func fetchOffers(
        repository: any OffersRepository,
        page: Int,
        pageSize: Int
    ) -> Observable<LoadPayload> {
        Observable.create { observer in
            let task = Task {
                do {
                    let offers = try await repository.fetchOffers(page: page, pageSize: pageSize)
                    observer.onNext(LoadPayload(page: page, offers: offers))
                    observer.onCompleted()
                } catch let networkError as AppNetworkError {
                    observer.onError(networkError)
                } catch {
                    observer.onError(AppNetworkError.unknown(message: error.localizedDescription))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func enrichOffers(_ offers: [OfferSummary]) -> [OfferSummary] {
        let savedIDs = (try? savedOffersStore.fetchSavedOfferIDs()) ?? []
        let now = Date()

        return offers.map { offer in
            OfferSummary(
                id: offer.id,
                title: offer.title,
                subtitle: offer.subtitle,
                imageURL: offer.imageURL,
                expiryDate: offer.expiryDate,
                isSaved: savedIDs.contains(offer.id),
                isExpired: offer.expiryDate < now
            )
        }
    }

    private func mergeWithoutDuplicates(
        existing: [OfferSummary],
        incoming: [OfferSummary]
    ) -> [OfferSummary] {
        let existingIDs = Set(existing.map(\.id))
        let filteredIncoming = incoming.filter { !existingIDs.contains($0.id) }
        return existing + filteredIncoming
    }
}

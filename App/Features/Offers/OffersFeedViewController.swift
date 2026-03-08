import DesignSystem
import FeaturesOffers
import Foundation
import RxCocoa
import RxSwift
import UIKit

final class OffersFeedViewController: UIViewController {
    typealias OfferSelectionHandler = (OfferSummary) -> Void
    typealias OfferSaveToggleHandler = (OfferSummary) -> Result<OfferSummary, Error>

    private static let expiryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var onOfferSelected: OfferSelectionHandler?
    var onOfferSaveToggleRequested: OfferSaveToggleHandler?

    private let viewModel: OffersFeedViewModel
    private let disposeBag = DisposeBag()
    private let retryTapRelay = PublishRelay<Void>()
    private let loadNextPageRelay = PublishRelay<Void>()

    private let stateContainer = ListStateContainerView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()
    private let paginationSpinner = UIActivityIndicatorView(style: .medium)

    private var offers: [OfferSummary] = []

    init(viewModel: OffersFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = stateContainer
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dsBackground
        configureTableView()
        bindViewModel()
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 118
        tableView.separatorStyle = .none
        tableView.register(OfferCardTableViewCell.self, forCellReuseIdentifier: OfferCardTableViewCell.reuseIdentifier)
        tableView.accessibilityIdentifier = "offers_table"
        tableView.dataSource = self
        tableView.delegate = self

        refreshControl.tintColor = .dsAccent
        tableView.refreshControl = refreshControl

        paginationSpinner.hidesWhenStopped = true
        tableView.tableFooterView = paginationSpinner

        stateContainer.contentView.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: stateContainer.contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: stateContainer.contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: stateContainer.contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: stateContainer.contentView.bottomAnchor)
        ])

        stateContainer.stateView.onRetry = { [weak self] in
            self?.retryTapRelay.accept(())
        }
    }

    private func bindViewModel() {
        let input = OffersFeedViewModel.Input(
            initialLoad: rx.viewWillAppear.take(1).map { _ in () }.asObservable(),
            pullToRefresh: refreshControl.rx.controlEvent(.valueChanged).asObservable(),
            retryTap: retryTapRelay.asObservable(),
            loadNextPage: loadNextPageRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.offers
            .drive(onNext: { [weak self] offers in
                self?.offers = offers
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        output.state
            .drive(onNext: { [weak self] state in
                self?.stateContainer.setState(state)

                if case .content = state {
                    self?.tableView.isHidden = false
                } else {
                    self?.tableView.isHidden = true
                }
            })
            .disposed(by: disposeBag)

        output.endRefreshing
            .emit(onNext: { [weak self] in
                self?.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)

        output.isPaginating
            .drive(onNext: { [weak self] isPaginating in
                if isPaginating {
                    self?.paginationSpinner.startAnimating()
                } else {
                    self?.paginationSpinner.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
    }

    func updateOfferState(_ updatedOffer: OfferSummary) {
        guard let index = offers.firstIndex(where: { $0.id == updatedOffer.id }) else {
            return
        }

        offers[index] = updatedOffer
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
}

extension OffersFeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        offers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: OfferCardTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? OfferCardTableViewCell
        else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let offer = offers[indexPath.row]
        cell.accessibilityIdentifier = "offer_card_\(offer.id)"
        cell.configure(with: offer, formatter: Self.expiryDateFormatter)
        cell.onSaveTapped = { [weak self] in
            self?.handleSaveTapped(forOfferID: offer.id)
        }
        return cell
    }

    private func handleSaveTapped(forOfferID offerID: String) {
        guard let index = offers.firstIndex(where: { $0.id == offerID }) else {
            return
        }
        guard let onOfferSaveToggleRequested else {
            return
        }

        let offer = offers[index]
        AppLogger.shared.info("Offer save tapped: \(offer.id)", category: .offers)
        switch onOfferSaveToggleRequested(offer) {
        case let .success(updatedOffer):
            offers[index] = updatedOffer
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            AppLogger.shared.info("Offer save state changed: \(updatedOffer.id)", category: .offers)
        case let .failure(error):
            AppLogger.shared.error("Offer save toggle failed: \(error.localizedDescription)", category: .offers)
            let alert = UIAlertController(
                title: "Could not update offer",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

extension OffersFeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let offer = offers[indexPath.row]
        AppLogger.shared.info("Offer selected: \(offer.id)", category: .offers)
        onOfferSelected?(offer)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row == offers.count - 1 else {
            return
        }

        loadNextPageRelay.accept(())
    }
}

import CoreData
import DesignSystem
import FeaturesOffers
import Foundation
import Persistence
import UIKit

final class SavedOffersViewController: UIViewController {
    var onOfferSelected: ((OfferSummary) -> Void)?

    private let savedOffersStore: any SavedOffersStoring
    private let stateContainer = ListStateContainerView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private lazy var fetchedResultsController = savedOffersStore.makeFetchedResultsController(sortedBy: .expiryDateAscending)

    init(savedOffersStore: any SavedOffersStoring) {
        self.savedOffersStore = savedOffersStore
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
        configureFetchedResultsController()
        refreshState()
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SavedOfferCell")
        tableView.accessibilityIdentifier = "saved_offers_table"
        tableView.dataSource = self
        tableView.delegate = self

        stateContainer.contentView.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: stateContainer.contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: stateContainer.contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: stateContainer.contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: stateContainer.contentView.bottomAnchor)
        ])
    }

    private func configureFetchedResultsController() {
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
    }

    private func refreshState() {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        if count == 0 {
            stateContainer.setState(
                .empty(
                    title: "No saved offers",
                    message: "Save offers from the feed to access them offline."
                )
            )
            tableView.isHidden = true
        } else {
            stateContainer.setState(.content)
            tableView.isHidden = false
        }
    }

    private func mapOffer(_ object: NSManagedObject) -> OfferSummary? {
        guard
            let id = object.value(forKey: "id") as? String,
            let title = object.value(forKey: "title") as? String,
            let subtitle = object.value(forKey: "subtitle") as? String,
            let expiryDate = object.value(forKey: "expiryDate") as? Date
        else {
            return nil
        }

        let imageURLString = object.value(forKey: "imageURLString") as? String
        return OfferSummary(
            id: id,
            title: title,
            subtitle: subtitle,
            imageURL: imageURLString.flatMap(URL.init(string:)),
            expiryDate: expiryDate,
            isSaved: true,
            isExpired: expiryDate < Date()
        )
    }
}

extension SavedOffersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController.sections?.count ?? 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedOfferCell", for: indexPath)
        let object = fetchedResultsController.object(at: indexPath)

        var content = cell.defaultContentConfiguration()
        if let offer = mapOffer(object) {
            content.text = offer.title
            content.secondaryText = offer.isExpired ? "Expired" : "Saved"
            content.image = UIImage(systemName: offer.isExpired ? "clock.badge.exclamationmark" : "bookmark.fill")
            content.imageProperties.tintColor = offer.isExpired ? .systemRed : .systemGreen
        } else {
            content.text = "Invalid saved offer"
            content.secondaryText = nil
        }

        cell.contentConfiguration = content
        if let id = object.value(forKey: "id") as? String {
            cell.accessibilityIdentifier = "saved_offer_card_\(id)"
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension SavedOffersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let object = fetchedResultsController.object(at: indexPath)
        guard let offer = mapOffer(object) else {
            return
        }
        onOfferSelected?(offer)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let unsaveAction = UIContextualAction(style: .destructive, title: "Unsave") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }

            let object = fetchedResultsController.object(at: indexPath)
            guard let id = object.value(forKey: "id") as? String else {
                completion(false)
                return
            }

            do {
                try savedOffersStore.unsave(offerID: id)
                completion(true)
            } catch {
                completion(false)
            }
        }
        return UISwipeActionsConfiguration(actions: [unsaveAction])
    }
}

extension SavedOffersViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
        refreshState()
    }
}

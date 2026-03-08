import CoreData
import DesignSystem
import Persistence
import UIKit

final class InboxViewController: UIViewController {
    var onUnreadCountChanged: ((Int) -> Void)?
    var onOpenMessageRequested: ((InboxMessage) -> Void)?

    private let inboxStore: any InboxStoring
    private let stateContainer = ListStateContainerView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()
    private lazy var fetchedResultsController = inboxStore.makeFetchedResultsController()

    init(inboxStore: any InboxStoring) {
        self.inboxStore = inboxStore
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "InboxCell")
        tableView.accessibilityIdentifier = "inbox_table"
        tableView.dataSource = self
        tableView.delegate = self

        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        stateContainer.contentView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: stateContainer.contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: stateContainer.contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: stateContainer.contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: stateContainer.contentView.bottomAnchor)
        ])

        stateContainer.stateView.onRetry = { [weak self] in
            self?.refreshFromSource()
        }
    }

    private func configureFetchedResultsController() {
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        emitUnreadCount()
    }

    @objc private func didPullToRefresh() {
        refreshFromSource()
    }

    private func refreshFromSource() {
        // Demo refresh merge for stale-state handling.
        let refreshed = InboxMessage(
            id: "msg-refresh-\(Int(Date().timeIntervalSince1970))",
            title: "Fresh promo update",
            body: "New personalized offers are available.",
            sentAt: Date(),
            isRead: false,
            deepLink: "retailrescue://offers",
            category: "promo"
        )

        do {
            try inboxStore.merge(messages: [refreshed])
            refreshControl.endRefreshing()
            stateContainer.setState(.content)
        } catch {
            SentryCrashReporter.shared.captureNonFatal(
                error,
                context: [
                    "feature": "inbox",
                    "operation": "refresh"
                ]
            )
            stateContainer.setState(
                .error(
                    title: "Inbox refresh failed",
                    message: error.localizedDescription,
                    retryTitle: "Retry"
                )
            )
            refreshControl.endRefreshing()
        }
    }

    private func refreshState() {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        if count == 0 {
            stateContainer.setState(
                .empty(
                    title: "Inbox is empty",
                    message: "Pull to refresh for latest transactional and promotional messages."
                )
            )
            tableView.isHidden = true
        } else {
            stateContainer.setState(.content)
            tableView.isHidden = false
        }
        emitUnreadCount()
    }

    private func emitUnreadCount() {
        let unread = (try? inboxStore.unreadCount()) ?? 0
        onUnreadCountChanged?(unread)
    }

    private func mapMessage(_ object: NSManagedObject) -> InboxMessage? {
        guard
            let id = object.value(forKey: "id") as? String,
            let title = object.value(forKey: "title") as? String,
            let body = object.value(forKey: "body") as? String,
            let sentAt = object.value(forKey: "sentAt") as? Date,
            let isRead = object.value(forKey: "isRead") as? Bool,
            let category = object.value(forKey: "category") as? String
        else {
            return nil
        }

        return InboxMessage(
            id: id,
            title: title,
            body: body,
            sentAt: sentAt,
            isRead: isRead,
            deepLink: object.value(forKey: "deepLink") as? String,
            category: category
        )
    }
}

extension InboxViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController.sections?.count ?? 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InboxCell", for: indexPath)
        let object = fetchedResultsController.object(at: indexPath)

        var content = cell.defaultContentConfiguration()
        if let message = mapMessage(object) {
            content.text = message.title
            content.secondaryText = message.body
            cell.accessoryType = .disclosureIndicator
            cell.accessibilityIdentifier = "inbox_message_\(message.id)"
            if message.isRead {
                content.textProperties.color = .dsTextSecondary
                content.secondaryTextProperties.color = .dsTextSecondary
            } else {
                content.textProperties.color = .dsTextPrimary
                content.secondaryTextProperties.color = .dsTextPrimary
            }
        } else {
            content.text = "Invalid message"
            content.secondaryText = nil
            cell.accessoryType = .none
            cell.accessibilityIdentifier = nil
        }

        cell.contentConfiguration = content
        return cell
    }
}

extension InboxViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let object = fetchedResultsController.object(at: indexPath)
        guard let message = mapMessage(object) else {
            return
        }

        try? inboxStore.markRead(messageID: message.id)
        emitUnreadCount()

        if let onOpenMessageRequested {
            onOpenMessageRequested(message)
            return
        }

        let detailViewController = MessageDetailViewController(message: message)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

extension InboxViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
        refreshState()
    }
}

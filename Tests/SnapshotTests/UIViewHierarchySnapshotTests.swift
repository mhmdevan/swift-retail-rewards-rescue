import DesignSystem
import FeaturesOffers
import Persistence
import XCTest
@testable import RetailRewardsRescue

final class UIViewHierarchySnapshotTests: XCTestCase {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    func testOfferCardSnapshotForSavedActiveOffer() {
        let cell = OfferCardTableViewCell(style: .default, reuseIdentifier: nil)
        let offer = OfferSummary(
            id: "offer-1",
            title: "20% off groceries",
            subtitle: "Weekend promo",
            imageURL: nil,
            expiryDate: Date().addingTimeInterval(86_400),
            isSaved: true,
            isExpired: false
        )

        cell.configure(with: offer, formatter: dateFormatter)
        cell.layoutIfNeeded()

        let snapshot = snapshotText(from: cell.contentView)
        XCTAssertTrue(snapshot.contains("UILabel[text=20% off groceries]"))
        XCTAssertTrue(snapshot.contains("UILabel[text=Weekend promo]"))
        XCTAssertTrue(snapshot.contains("UIButton[title=nil enabled=true]"))
    }

    func testOfferCardSnapshotForExpiredOffer() {
        let cell = OfferCardTableViewCell(style: .default, reuseIdentifier: nil)
        let offer = OfferSummary(
            id: "offer-2",
            title: "Coffee bonus",
            subtitle: "Morning offer",
            imageURL: nil,
            expiryDate: Date().addingTimeInterval(-100),
            isSaved: false,
            isExpired: true
        )

        cell.configure(with: offer, formatter: dateFormatter)
        cell.layoutIfNeeded()

        let snapshot = snapshotText(from: cell.contentView)
        XCTAssertTrue(snapshot.contains("UILabel[text=Coffee bonus]"))
        XCTAssertTrue(snapshot.contains("UILabel[text=Morning offer]"))
        XCTAssertTrue(snapshot.contains("UIButton[title=nil enabled=false]"))
    }

    func testOfferDetailSnapshotForExpiredState() {
        let stack = PersistenceCoreDataStack(inMemory: true)
        let store = CoreDataSavedOffersStore(stack: stack)
        let service = OfferSaveService(store: store)
        let offer = OfferSummary(
            id: "detail-1",
            title: "Expired offer",
            subtitle: "No longer valid",
            imageURL: nil,
            expiryDate: Date().addingTimeInterval(-1_000),
            isSaved: false,
            isExpired: true
        )

        let viewController = OfferDetailViewController(offer: offer, saveService: service)
        viewController.loadViewIfNeeded()

        let snapshot = snapshotText(from: viewController.view)
        XCTAssertTrue(snapshot.contains("UILabel[text=Expired offer]"))
        XCTAssertTrue(snapshot.contains("UILabel[text=No longer valid]"))
        XCTAssertTrue(snapshot.contains("UIButton[title=Expired enabled=false]"))
    }

    func testContentStateViewSnapshotForEmptyState() {
        let view = ContentStateView(frame: CGRect(x: 0, y: 0, width: 375, height: 240))
        view.render(.empty(title: "No data", message: "Try again later"))

        let snapshot = snapshotText(from: view)
        XCTAssertTrue(snapshot.contains("UILabel[text=No data]"))
        XCTAssertTrue(snapshot.contains("UILabel[text=Try again later]"))
    }

    func testContentStateViewSnapshotForErrorState() {
        let view = ContentStateView(frame: CGRect(x: 0, y: 0, width: 375, height: 240))
        view.render(.error(title: "Failed", message: "Network issue", retryTitle: "Retry"))

        let snapshot = snapshotText(from: view)
        XCTAssertTrue(snapshot.contains("UILabel[text=Failed]"))
        XCTAssertTrue(snapshot.contains("UILabel[text=Network issue]"))
        XCTAssertTrue(snapshot.contains("UIButton[title=Retry enabled=true]"))
    }

    private func snapshotText(from rootView: UIView) -> String {
        var lines: [String] = []

        func visit(view: UIView, depth: Int) {
            let prefix = String(repeating: "  ", count: depth)
            lines.append(prefix + describe(view: view))
            view.subviews.forEach { visit(view: $0, depth: depth + 1) }
        }

        visit(view: rootView, depth: 0)
        return lines.joined(separator: "\n")
    }

    private func describe(view: UIView) -> String {
        if let label = view as? UILabel {
            return "UILabel[text=\(label.text ?? "nil")]"
        }

        if let button = view as? UIButton {
            return "UIButton[title=\(button.title(for: .normal) ?? "nil") enabled=\(button.isEnabled)]"
        }

        return "\(type(of: view))"
    }
}

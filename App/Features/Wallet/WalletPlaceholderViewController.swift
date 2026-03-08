import FeaturesOffers
import SwiftUI
import UIKit

final class WalletPlaceholderViewController: UIViewController {
    private let offersRepository: any OffersRepository

    init(offersRepository: any OffersRepository) {
        self.offersRepository = offersRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let walletViewModel = RewardsWalletViewModel(offersRepository: offersRepository)
        let walletView = RewardsWalletView(viewModel: walletViewModel)
        let hostingController = UIHostingController(rootView: walletView)

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}

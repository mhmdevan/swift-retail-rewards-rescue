import Core
import DesignSystem
import FeaturesOffers
import Persistence
import Routing
import UIKit

@MainActor
final class AppCoordinator: Coordinator {
    private let window: UIWindow
    private let dependencies: AppDependencyContainer
    private let routeParser = AppRouteParser()
    private weak var activeTabBarController: UITabBarController?

    init(window: UIWindow, dependencies: AppDependencyContainer) {
        self.window = window
        self.dependencies = dependencies
    }

    func start() {
        _ = try? dependencies.offerSaveService.reconcileExpiry()

        let session = dependencies.sessionStore.restore()
        let destination = dependencies.launchDestinationResolver.resolve(session: session)

        switch destination {
        case .login:
            showLogin()
        case .mainShell:
            showMainShell()
        case .biometricUnlock:
            showBiometricGate()
        }

        window.makeKeyAndVisible()
    }

    private func showLogin(
        statusMessage: String? = nil,
        tone: LoginViewController.StatusTone = .info
    ) {
        let loginViewController = LoginViewController(
            validator: dependencies.loginFormValidator,
            initialStatusMessage: statusMessage,
            initialStatusTone: tone
        )

        loginViewController.onSubmit = { [weak self] input in
            guard let self else {
                return .failure("Internal coordinator deallocated.")
            }
            return await self.handleLogin(input: input)
        }

        let navigationController = UINavigationController(rootViewController: loginViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        window.rootViewController = navigationController
    }

    private func showBiometricGate() {
        let availability = dependencies.biometricAuthenticator.availability()

        guard case let .available(type) = availability else {
            let reason = {
                if case let .unavailable(reason) = availability {
                    return reason
                }
                return "Biometric authentication is unavailable."
            }()

            fallbackToPasswordLogin(reason: reason)
            return
        }

        let gateViewController = BiometricGateViewController(biometricType: type)
        gateViewController.onAuthenticate = { [weak self] in
            guard let self else {
                return .failed(message: "Internal coordinator deallocated.")
            }

            return await self.dependencies.biometricAuthenticator.authenticate(
                reason: "Unlock your Retail Rewards Rescue account"
            )
        }

        gateViewController.onUnlockSucceeded = { [weak self] in
            self?.showMainShell()
        }

        gateViewController.onFallbackToPassword = { [weak self] in
            self?.fallbackToPasswordLogin(reason: "Use password login to continue.")
        }

        let navigationController = UINavigationController(rootViewController: gateViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        window.rootViewController = navigationController
    }

    private func fallbackToPasswordLogin(reason: String) {
        try? dependencies.sessionStore.clear()
        showLogin(statusMessage: "Biometric unlock was not completed: \(reason)", tone: .info)
    }

    private func handleLogin(input: LoginSubmissionInput) async -> Result<Void, String> {
        do {
            let authenticatedSession = try await dependencies.authService.login(
                email: input.email,
                password: input.password
            )

            let updatedSession = UserSession(
                userId: authenticatedSession.userId,
                email: authenticatedSession.email,
                authToken: authenticatedSession.authToken,
                refreshToken: authenticatedSession.refreshToken,
                biometricEnabled: input.biometricEnabled,
                lastLoginDate: Date()
            )

            try dependencies.sessionStore.save(updatedSession)
            showMainShell()
            return .success(())
        } catch let validationError as AuthValidationError {
            return .failure(validationError.localizedDescription)
        } catch let persistenceError as SessionPersistenceError {
            return .failure(persistenceError.localizedDescription)
        } catch {
            return .failure("Unexpected login failure. Please retry.")
        }
    }

    private func showMainShell() {
        let offersFeedViewModel = OffersFeedViewModel(
            repository: dependencies.legacyOffersRepository,
            savedOffersStore: dependencies.savedOffersStore,
            schedulers: dependencies.schedulerProvider
        )
        let offersFeedViewController = OffersFeedViewController(viewModel: offersFeedViewModel)

        let savedOffersViewController = SavedOffersViewController(savedOffersStore: dependencies.savedOffersStore)

        let inboxViewController = InboxViewController(inboxStore: dependencies.inboxStore)
        let walletViewController = WalletPlaceholderViewController(
            offersRepository: dependencies.modernOffersRepository
        )

        let settingsViewController = SettingsViewController()
        settingsViewController.onLogoutRequested = { [weak self] in
            self?.handleLogout()
        }

        let offersNavigation = makeTabNavigation(root: offersFeedViewController, title: "Offers", systemImage: "tag.fill")
        let savedNavigation = makeTabNavigation(root: savedOffersViewController, title: "Saved", systemImage: "bookmark.fill")
        let inboxNavigation = makeTabNavigation(root: inboxViewController, title: "Inbox", systemImage: "tray.full.fill")
        let membershipNavigation = makeTabNavigation(root: MembershipCardViewController(), title: "Card", systemImage: "qrcode")
        let walletNavigation = makeTabNavigation(root: walletViewController, title: "Wallet", systemImage: "wallet.pass.fill")
        let settingsNavigation = makeTabNavigation(root: settingsViewController, title: "Settings", systemImage: "gearshape.fill")
        settingsViewController.onDiagnosticsRequested = { [weak self, weak settingsNavigation] in
            self?.showDiagnostics(on: settingsNavigation)
        }

        offersFeedViewController.onOfferSelected = { [weak self, weak offersNavigation, weak offersFeedViewController] offer in
            guard let self else { return }
            self.showOfferDetail(
                on: offersNavigation,
                offer: offer,
                offersFeedViewController: offersFeedViewController
            )
        }
        offersFeedViewController.onOfferSaveToggleRequested = { [weak self] offer in
            guard let self else {
                return .failure(NSError(domain: "AppCoordinator", code: -1))
            }
            do {
                let updated = try self.dependencies.offerSaveService.toggleSave(for: offer)
                return .success(updated)
            } catch {
                return .failure(error)
            }
        }

        savedOffersViewController.onOfferSelected = { [weak self, weak savedNavigation] offer in
            guard let self else { return }
            self.showOfferDetail(on: savedNavigation, offer: offer, offersFeedViewController: nil)
        }

        inboxViewController.onUnreadCountChanged = { [weak inboxNavigation] unreadCount in
            inboxNavigation?.tabBarItem.badgeValue = unreadCount > 0 ? String(unreadCount) : nil
        }

        inboxViewController.onOpenMessageRequested = { [weak self, weak inboxNavigation] message in
            self?.openMessageDetail(on: inboxNavigation, message: message)
        }

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            offersNavigation,
            savedNavigation,
            inboxNavigation,
            membershipNavigation,
            walletNavigation,
            settingsNavigation
        ]
        tabBarController.tabBar.tintColor = .dsAccent
        tabBarController.tabBar.backgroundColor = .dsSurface

        window.rootViewController = tabBarController
        activeTabBarController = tabBarController

        let unreadCount = (try? dependencies.inboxStore.unreadCount()) ?? 0
        inboxNavigation.tabBarItem.badgeValue = unreadCount > 0 ? String(unreadCount) : nil
    }

    private func showOfferDetail(
        on navigationController: UINavigationController?,
        offer: OfferSummary,
        offersFeedViewController: OffersFeedViewController?
    ) {
        let detail = OfferDetailViewController(offer: offer, saveService: dependencies.offerSaveService)
        detail.onSaveStateChanged = { updatedOffer in
            offersFeedViewController?.updateOfferState(updatedOffer)
        }
        navigationController?.pushViewController(detail, animated: true)
    }

    private func showDiagnostics(on navigationController: UINavigationController?) {
        let diagnosticsViewController = DiagnosticsViewController(
            backgroundRefreshManager: AppRuntimeContext.backgroundRefreshManager
        )
        diagnosticsViewController.onRouteTestRequested = { [weak self] routeValue in
            self?.handleDeepLink(routeValue)
        }
        navigationController?.pushViewController(diagnosticsViewController, animated: true)
    }

    func handleIncomingURL(_ url: URL) {
        AppLogger.shared.info(
            "Incoming URL received",
            category: .routing,
            metadata: ["url": url.absoluteString],
            redactedKeys: ["url"]
        )
        handleRoute(routeParser.parse(url: url))
    }

    private func handleDeepLink(_ deepLink: String) {
        guard let url = URL(string: deepLink), let route = routeParser.parse(url: url) else {
            AppLogger.shared.error(
                "Deep link parse failed",
                category: .routing,
                metadata: ["raw_value": deepLink],
                redactedKeys: ["raw_value"]
            )
            return
        }
        AppLogger.shared.debug("Deep link parsed", category: .routing, metadata: ["route": "\(route)"])
        handleRoute(route)
    }

    private func handleRoute(_ route: AppRoute?) {
        guard let route else {
            AppLogger.shared.error("Route resolution returned nil", category: .routing)
            return
        }

        switch route {
        case .offers:
            selectTab(index: 0)
        case .inbox:
            selectTab(index: 2)
        case .wallet:
            selectTab(index: 4)
        case let .offerDetail(id):
            openOfferDetailFromRoute(offerID: id)
        case let .inboxMessage(id):
            openInboxMessageFromRoute(messageID: id)
        }
    }

    private func selectTab(index: Int) {
        guard let tabBarController = activeTabBarController,
              index < (tabBarController.viewControllers?.count ?? 0)
        else {
            return
        }

        tabBarController.selectedIndex = index
    }

    private func openOfferDetailFromRoute(offerID: String) {
        guard let tabBarController = activeTabBarController,
              let navigationController = tabBarController.viewControllers?[0] as? UINavigationController
        else {
            return
        }

        tabBarController.selectedIndex = 0

        Task { [weak self] in
            guard let self else { return }

            let fetchedOffers = try? await dependencies.legacyOffersRepository.fetchOffers(page: 1, pageSize: 50)
            let matchedOffer = fetchedOffers?.first(where: { $0.id == offerID })
            let offer = matchedOffer ?? OfferSummary(
                id: offerID,
                title: "Routed Offer \(offerID)",
                subtitle: "Loaded from deep-link route",
                imageURL: nil,
                expiryDate: Date().addingTimeInterval(60 * 60 * 24 * 14)
            )

            await MainActor.run {
                let detail = OfferDetailViewController(offer: offer, saveService: dependencies.offerSaveService)
                navigationController.pushViewController(detail, animated: true)
            }
        }
    }

    private func openInboxMessageFromRoute(messageID: String) {
        guard let tabBarController = activeTabBarController,
              let navigationController = tabBarController.viewControllers?[2] as? UINavigationController
        else {
            return
        }

        tabBarController.selectedIndex = 2

        if let message = try? dependencies.inboxStore.fetchMessage(id: messageID), let message {
            openMessageDetail(on: navigationController, message: message)
        }
    }

    private func openMessageDetail(on navigationController: UINavigationController?, message: InboxMessage) {
        let detail = MessageDetailViewController(message: message)
        detail.onRouteOpenRequested = { [weak self] routeValue in
            self?.handleDeepLink(routeValue)
        }
        navigationController?.pushViewController(detail, animated: true)
    }

    private func handleLogout() {
        do {
            try dependencies.sessionStore.clear()
            showLogin(statusMessage: "Session cleared. Sign in again.", tone: .info)
        } catch {
            showLogin(statusMessage: "Failed to clear secure session. Sign in again.", tone: .error)
        }
    }

    private func makeTabNavigation(root: UIViewController, title: String, systemImage: String) -> UINavigationController {
        root.navigationItem.title = title
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: systemImage),
            selectedImage: nil
        )
        return navigationController
    }
}

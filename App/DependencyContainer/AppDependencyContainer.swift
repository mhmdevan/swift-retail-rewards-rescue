import Core
import FeaturesOffers
import Foundation
import NetworkingModern
import Persistence

final class AppDependencyContainer {
    let sessionStore: SessionStoring
    let authService: any AuthServicing
    let launchDestinationResolver: LaunchDestinationResolver
    let loginFormValidator: any LoginFormValidating
    let biometricAuthenticator: any BiometricAuthenticating

    let schedulerProvider: SchedulerProviding
    let legacyOffersRepository: any OffersRepository
    let modernOffersRepository: any OffersRepository

    let persistenceStack: PersistenceCoreDataStack
    let savedOffersStore: any SavedOffersStoring
    let inboxStore: any InboxStoring
    let offerSaveService: OfferSaveService

    init(
        sessionStore: SessionStoring? = nil,
        authService: any AuthServicing = MockAuthService(),
        launchDestinationResolver: LaunchDestinationResolver = .init(),
        loginFormValidator: any LoginFormValidating = LoginFormValidator(),
        biometricAuthenticator: any BiometricAuthenticating = LocalBiometricAuthenticator(),
        schedulerProvider: SchedulerProviding = DefaultSchedulerProvider()
    ) {
        self.sessionStore = sessionStore ??
            PersistentSessionStore(
                secureStore: KeychainSecureDataStore(service: "com.evan.retailrewardsrescue.session"),
                restoreOnInit: true
            )
        self.authService = authService
        self.launchDestinationResolver = launchDestinationResolver
        self.loginFormValidator = loginFormValidator
        self.biometricAuthenticator = biometricAuthenticator
        self.schedulerProvider = schedulerProvider

        persistenceStack = PersistenceCoreDataStack(inMemory: false)
        let savedOffersStore = CoreDataSavedOffersStore(stack: persistenceStack)
        let inboxStore = CoreDataInboxStore(stack: persistenceStack)
        self.savedOffersStore = savedOffersStore
        self.inboxStore = inboxStore
        offerSaveService = OfferSaveService(store: savedOffersStore)

        let legacyClient = AlamofireLegacyNetworkClient(
            baseURL: URL(string: "https://legacy.retailrewardsrescue.local")!,
            session: LegacyNetworkingFactory.makeDemoAlamofireSession()
        )
        self.legacyOffersRepository = LegacyOffersRepository(network: legacyClient)

        let modernDecoder = JSONDecoder()
        modernDecoder.dateDecodingStrategy = .iso8601
        let modernClient = URLSessionModernClient(
            baseURL: URL(string: "https://modern.retailrewardsrescue.local")!,
            session: LegacyNetworkingFactory.makeDemoURLSession(),
            decoder: modernDecoder
        )
        self.modernOffersRepository = ModernOffersRepository(client: modernClient)

        seedInboxIfNeeded()
    }

    private func seedInboxIfNeeded() {
        guard let currentUnread = try? inboxStore.unreadCount(), currentUnread == 0 else {
            return
        }

        let seedMessages = [
            InboxMessage(
                id: "msg-1",
                title: "Welcome to Rewards",
                body: "Thanks for joining. Check your offers for this week.",
                sentAt: Date().addingTimeInterval(-7200),
                isRead: false,
                deepLink: "retailrescue://offers",
                category: "promo"
            ),
            InboxMessage(
                id: "msg-2",
                title: "Points Statement",
                body: "Your monthly points statement is ready.",
                sentAt: Date().addingTimeInterval(-3600),
                isRead: false,
                deepLink: "retailrescue://wallet",
                category: "transactional"
            )
        ]

        try? inboxStore.merge(messages: seedMessages)
    }
}

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        let dependencies = AppDependencyContainer()
        let appCoordinator = AppCoordinator(window: window, dependencies: dependencies)

        self.window = window
        self.appCoordinator = appCoordinator
        AppRuntimeContext.dependencies = dependencies

        appCoordinator.start()

        if let incomingURL = connectionOptions.urlContexts.first?.url {
            appCoordinator.handleIncomingURL(incomingURL)
        }

        if let webpageURL = connectionOptions.userActivities
            .first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb })?
            .webpageURL {
            appCoordinator.handleIncomingURL(webpageURL)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        appCoordinator?.handleIncomingURL(url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
            return
        }
        appCoordinator?.handleIncomingURL(url)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        AppRuntimeContext.backgroundRefreshManager.runForegroundRefreshIfNeeded()
    }
}

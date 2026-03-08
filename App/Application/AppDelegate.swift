import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppLogger.shared.info("Application did finish launching", category: .app)
        SentryCrashReporter.shared.configureIfPossible()
        MetricKitObserver.shared.start()
        AppRuntimeContext.backgroundRefreshManager.register()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AppRuntimeContext.backgroundRefreshManager.schedule()
    }
}

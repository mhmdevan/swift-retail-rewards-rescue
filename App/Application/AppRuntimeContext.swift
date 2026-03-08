import Foundation

enum AppRuntimeContext {
    static var dependencies: AppDependencyContainer?

    static let backgroundRefreshManager = BackgroundRefreshManager {
        if let dependencies {
            return dependencies
        }
        let fallback = AppDependencyContainer()
        dependencies = fallback
        return fallback
    }
}

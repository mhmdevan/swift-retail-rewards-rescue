import Foundation

#if canImport(Sentry)
import Sentry
#endif

final class SentryCrashReporter {
    static let shared = SentryCrashReporter()

    private init() {}

    func configureIfPossible() {
        #if canImport(Sentry)
        let bundle = Bundle.main
        let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"

        #if DEBUG
        let environment = "debug"
        #else
        let environment = "release"
        #endif

        SentrySDK.start { options in
            options.dsn = bundle.object(forInfoDictionaryKey: "SENTRY_DSN") as? String ?? ""
            options.environment = environment
            options.releaseName = "retail-rewards-rescue@\(appVersion)+\(buildNumber)"
            options.sendDefaultPii = false
            options.debug = environment == "debug"
            options.tracesSampleRate = 0.2
        }

        SentrySDK.configureScope { scope in
            scope.setTag(value: environment, key: "environment")
            scope.setTag(value: appVersion, key: "app_version")
            scope.setTag(value: buildNumber, key: "build_number")
        }
        #endif
    }

    func captureTestError() {
        #if canImport(Sentry)
        SentrySDK.capture(message: "Diagnostics test error capture")
        #endif
    }

    func captureNonFatal(_ error: Error, context: [String: String] = [:]) {
        #if canImport(Sentry)
        SentrySDK.configureScope { scope in
            context.forEach { key, value in
                scope.setTag(value: value, key: key)
            }
        }
        SentrySDK.capture(error: error)
        #endif
    }
}

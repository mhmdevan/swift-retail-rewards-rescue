import BackgroundTasks
import Foundation

final class BackgroundRefreshManager {
    static let taskIdentifier = "com.evan.retailrewardsrescue.refresh"

    enum RefreshTrigger: String {
        case foreground = "foreground"
        case backgroundTask = "background_task"
        case diagnosticsManual = "diagnostics_manual"
    }

    private let dependenciesProvider: () -> AppDependencyContainer
    private let userDefaults: UserDefaults
    private let stateQueue = DispatchQueue(label: "com.evan.retailrewardsrescue.background.refresh.state")

    private var isRefreshInProgress = false
    private let lastRefreshKey = "com.evan.retailrewardsrescue.background.last-success"
    private let foregroundTTL: TimeInterval = 5 * 60
    private let backgroundTTL: TimeInterval = 30 * 60

    init(
        dependenciesProvider: @escaping () -> AppDependencyContainer,
        userDefaults: UserDefaults = .standard
    ) {
        self.dependenciesProvider = dependenciesProvider
        self.userDefaults = userDefaults
    }

    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self?.handle(task: processingTask)
        }
    }

    func schedule() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date().addingTimeInterval(backgroundTTL)

        do {
            try BGTaskScheduler.shared.submit(request)
            AppLogger.shared.info("Background refresh task scheduled", category: .background)
        } catch {
            AppLogger.shared.error("Failed to schedule background refresh: \(error.localizedDescription)", category: .background)
        }
    }

    func runForegroundRefreshIfNeeded() {
        runRefresh(trigger: .foreground, force: false, completion: nil)
    }

    func runRefreshNowForDebug() {
        runRefresh(trigger: .diagnosticsManual, force: true, completion: nil)
    }

    var lastRefreshDescription: String {
        guard let date = userDefaults.object(forKey: lastRefreshKey) as? Date else {
            return "Never"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func runRefresh(
        trigger: RefreshTrigger,
        force: Bool,
        completion: ((Bool) -> Void)?
    ) {
        let shouldStart = stateQueue.sync { () -> Bool in
            if isRefreshInProgress {
                AppLogger.shared.info("Refresh ignored; another refresh is in progress", category: .background)
                return false
            }

            if !force, shouldThrottle(trigger: trigger) {
                AppLogger.shared.info("Refresh throttled for trigger=\(trigger.rawValue)", category: .background)
                return false
            }

            isRefreshInProgress = true
            return true
        }

        guard shouldStart else {
            completion?(true)
            return
        }

        Task {
            let success = await executeRefreshPipeline(trigger: trigger)
            stateQueue.async { [weak self] in
                guard let self else { return }
                self.isRefreshInProgress = false
                if success {
                    self.userDefaults.set(Date(), forKey: self.lastRefreshKey)
                }
            }
            completion?(success)
        }
    }

    private func shouldThrottle(trigger: RefreshTrigger) -> Bool {
        guard let lastDate = userDefaults.object(forKey: lastRefreshKey) as? Date else {
            return false
        }

        let ttl: TimeInterval
        switch trigger {
        case .foreground:
            ttl = foregroundTTL
        case .backgroundTask:
            ttl = backgroundTTL
        case .diagnosticsManual:
            return false
        }

        return Date().timeIntervalSince(lastDate) < ttl
    }

    private func executeRefreshPipeline(trigger: RefreshTrigger) async -> Bool {
        let dependencies = dependenciesProvider()

        do {
            _ = try await dependencies.legacyOffersRepository.fetchOffers(page: 1, pageSize: 10)

            _ = try dependencies.offerSaveService.reconcileExpiry()
            try dependencies.inboxStore.merge(messages: [
                InboxMessage(
                    id: "bg-refresh-\(Int(Date().timeIntervalSince1970))",
                    title: "Background refresh update",
                    body: "Inbox refreshed by \(trigger.rawValue).",
                    sentAt: Date(),
                    isRead: false,
                    deepLink: "retailrescue://inbox",
                    category: "transactional"
                )
            ])

            AppLogger.shared.info("Refresh pipeline completed: trigger=\(trigger.rawValue)", category: .background)
            return true
        } catch {
            AppLogger.shared.error(
                "Refresh pipeline failed: trigger=\(trigger.rawValue) error=\(error.localizedDescription)",
                category: .background
            )
            SentryCrashReporter.shared.captureNonFatal(
                error,
                context: [
                    "feature": "background_refresh",
                    "trigger": trigger.rawValue
                ]
            )
            return false
        }
    }

    private func handle(task: BGProcessingTask) {
        schedule()

        task.expirationHandler = {
            AppLogger.shared.error("Background task expired before completion", category: .background)
        }

        runRefresh(trigger: .backgroundTask, force: false) { success in
            task.setTaskCompleted(success: success)
        }
    }
}

import DesignSystem
import Foundation
import SDWebImage
import UIKit

final class DiagnosticsViewController: UIViewController {
    private let backgroundRefreshManager: BackgroundRefreshManager

    private let stackView = UIStackView()
    private let infoLabel = UILabel()
    private let metricsLabel = UILabel()
    private let routeTextField = UITextField()
    private let routeShortcutControl = UISegmentedControl(items: ["Offers", "Detail", "Inbox", "Wallet"])
    private let routeButton = UIButton(type: .system)
    private let bgRefreshButton = UIButton(type: .system)
    private let clearCacheButton = UIButton(type: .system)
    private let sentryButton = UIButton(type: .system)
    private let crashButton = UIButton(type: .system)

    var onRouteTestRequested: ((String) -> Void)?

    init(backgroundRefreshManager: BackgroundRefreshManager) {
        self.backgroundRefreshManager = backgroundRefreshManager
        super.init(nibName: nil, bundle: nil)
        title = "Diagnostics"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dsBackground
        configureLayout()
        refreshInfo()
    }

    private func configureLayout() {
        stackView.axis = .vertical
        stackView.spacing = DSSpacing.md
        stackView.translatesAutoresizingMaskIntoConstraints = false

        infoLabel.font = DSTypography.body()
        infoLabel.textColor = .dsTextPrimary
        infoLabel.numberOfLines = 0

        metricsLabel.font = DSTypography.caption()
        metricsLabel.textColor = .dsTextSecondary
        metricsLabel.numberOfLines = 0

        routeTextField.placeholder = "retailrescue://offers"
        routeTextField.borderStyle = .roundedRect
        routeTextField.text = "retailrescue://offers"

        routeShortcutControl.selectedSegmentIndex = 0
        routeShortcutControl.addTarget(self, action: #selector(didChangeRouteShortcut), for: .valueChanged)

        routeButton.setTitle("Test Route", for: .normal)
        routeButton.addTarget(self, action: #selector(didTapRouteTest), for: .touchUpInside)

        bgRefreshButton.setTitle("Run Background Refresh", for: .normal)
        bgRefreshButton.addTarget(self, action: #selector(didTapBackgroundRefresh), for: .touchUpInside)

        clearCacheButton.setTitle("Clear Image/URL Cache", for: .normal)
        clearCacheButton.addTarget(self, action: #selector(didTapClearCache), for: .touchUpInside)

        sentryButton.setTitle("Capture Test Error", for: .normal)
        sentryButton.addTarget(self, action: #selector(didTapSentry), for: .touchUpInside)

        crashButton.setTitle("Trigger Test Crash (Debug)", for: .normal)
        crashButton.setTitleColor(.dsDanger, for: .normal)
        crashButton.addTarget(self, action: #selector(didTapCrash), for: .touchUpInside)
        #if !DEBUG
        crashButton.isHidden = true
        #endif

        [infoLabel, metricsLabel, routeTextField, routeShortcutControl, routeButton, bgRefreshButton, clearCacheButton, sentryButton, crashButton]
            .forEach { stackView.addArrangedSubview($0) }

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DSSpacing.lg),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: DSSpacing.md),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DSSpacing.md)
        ])
    }

    private func refreshInfo() {
        let bundle = Bundle.main
        let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        #if DEBUG
        let buildType = "Debug"
        #else
        let buildType = "Release"
        #endif

        infoLabel.text = """
        Version: \(appVersion) (\(build))
        Build Type: \(buildType)
        Environment: Demo
        Background Task: \(BackgroundRefreshManager.taskIdentifier)
        Last Successful Refresh: \(backgroundRefreshManager.lastRefreshDescription)
        """
        metricsLabel.text = "MetricKit: \(MetricKitObserver.shared.latestPayloadSummary)"
    }

    @objc private func didTapRouteTest() {
        guard let value = routeTextField.text, !value.isEmpty else {
            return
        }
        onRouteTestRequested?(value)
    }

    @objc private func didTapBackgroundRefresh() {
        backgroundRefreshManager.runRefreshNowForDebug()
        refreshInfo()
    }

    @objc private func didTapClearCache() {
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk(onCompletion: nil)
        AppLogger.shared.info("Diagnostics cache clear executed", category: .app)
    }

    @objc private func didTapSentry() {
        SentryCrashReporter.shared.captureTestError()
        AppLogger.shared.info("Diagnostics sentry capture executed", category: .app)
    }

    @objc private func didTapCrash() {
        #if DEBUG
        fatalError("Diagnostics test crash triggered")
        #endif
    }

    @objc private func didChangeRouteShortcut() {
        switch routeShortcutControl.selectedSegmentIndex {
        case 0:
            routeTextField.text = "retailrescue://offers"
        case 1:
            routeTextField.text = "retailrescue://offers/detail/offer-1"
        case 2:
            routeTextField.text = "retailrescue://inbox/message/msg-1"
        case 3:
            routeTextField.text = "retailrescue://wallet"
        default:
            break
        }
    }
}
